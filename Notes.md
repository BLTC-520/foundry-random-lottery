Lesson 9 Notes
## Natspec
Learning Writing NatSpec (need to download `Solidity` extension by Juan Blanco)
use `///` or `/** + Enter/` to have a natspec template for writing clear information for a contract or function

| Tag           | Use Case                                                 |
| ------------- | -------------------------------------------------------- |
| `@title`      | Short title for a contract/interface                     |
| `@author`     | Who wrote the code                                       |
| `@notice`     | What users (end-users) should know about this item       |
| `@dev`        | Technical details for developers                         |
| `@param`      | Document each parameter (`@param name description`)      |
| `@return`     | Document return values (`@return valueName description`) |
| `@inheritdoc` | Inherit NatSpec from parent (saves repetition)           |
| `@custom:tag` | Custom tags (e.g. `@custom:security`)                    |

## Solidity Layout Guide 
```bash
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
```

[Solidity Layout Guide](https://docs.soliditylang.org/en/latest/style-guide.html)

## Custom Errors 
```bash
    error ExampleRevert__Error();

    function revertWithError() public pure { ---> costs 142 gas
        if(false) {
            revert ExampleRevert__Error();
        }
    }

    function reverWithRequire() public pure { ---> costs 161 gas 
        if(false) {
            require(true, "ExampleRevert__Error"); 
        }
    }

    // more gas efficient using custom errors. (^0.8.4)
```

**Naming Practice: Name the error's prefix with your contract name.**

```bash
    if(msg.value < i_entranceFee) {
                revert Raffle__SendMoreToEnterRaffle(); // ---> Contract: Raffle.sol
    }
```

## Events

The reason emitting events makes life **easier for the frontend** is because of how Ethereum (and other EVM chains) work:

---

### 🔹 Why Events Help Frontends

1. **Efficient "indexing":**

   * Events are logged in transaction receipts and stored in the blockchain log system.
   * Unlike storage variables, events are **indexed by topics**, so you can quickly search/filter by event type or arguments.
   * Example: `RaffleEnter(address indexed player)` lets you query *only entries from a specific player* directly via an RPC provider (e.g. Alchemy, Infura, or TheGraph).

2. **Cheaper to query than storage:**

   * Reading state (e.g. `s_players`) requires a call to the contract → more expensive and sometimes requires off-chain parsing.
   * Events are designed for **off-chain consumption**, so they’re lightweight to fetch and filter.

3. **Frontend reactivity:**

   * Your dApp can "listen" for `RaffleEnter` events in real time (using ethers.js or wagmi hooks). (This is super important!)
   * This means the UI updates automatically when someone enters the raffle — without needing constant `call`s to check `s_players`.

4. **Migration / transparency:**

   * If you redeploy the contract (new address), the historical log of who entered still exists in the event logs, even if `s_players` gets reset.
   * The frontend can reconstruct past activity from logs.

---

### 🔹 Example (Ethers.js / wagmi)

```javascript
contract.on("RaffleEnter", (player) => {
  console.log("New entry:", player);
  updateUI();
});
```

That way the frontend **reacts instantly** when someone calls the function — no need to poll the chain for changes.

---
In short: Emitting events = **easy filtering, fast lookups, and reactive frontends.**
Without them, you’d have to constantly read contract storage (expensive + less reliable).

### Indexed Keyword
In Solidity, the **`indexed`** keyword marks event parameters so they get stored as **topics** in the transaction logs.

---

### 🔹 How it works

* Each event log has:

  * **1 topic** = the event signature (`keccak256("EventName(type1,type2,...)")`)
  * **Up to 3 additional topics** = values of `indexed` parameters
  * **All other parameters** (non-indexed) are stored in the **data field** of the log

So max = **4 topics total** (event signature + 3 indexed params).

---

### 🔹 Example

```solidity
event RaffleEnter(address indexed player, uint256 indexed round, uint256 amount);
```

* `player` and `round` go into **topics** (easy to filter by address or round number).
* `amount` goes into the **data field** (you can still read it, but can’t filter directly by it when querying).

---

### 🔹 Querying

With `indexed`, the frontend can filter directly:

```javascript
// Ethers.js example
contract.queryFilter(
  contract.filters.RaffleEnter("0x1234..."), // filter by player
  fromBlock,
  toBlock
);
```

```javascript
// Wagmi Example
import { useEffect } from "react";
import { useWatchContractEvent } from "wagmi";

const contractConfig = {
  address: "0xYourContractAddress",
  abi: [
    {
      type: "event",
      name: "RaffleEnter",
      inputs: [
        { name: "player", type: "address", indexed: true },
        { name: "round", type: "uint256", indexed: true },
        { name: "amount", type: "uint256", indexed: false },
      ],
    },
  ],
};

export function RaffleListener() {
  useWatchContractEvent({
    ...contractConfig,
    eventName: "RaffleEnter",
    onLogs(logs) {
      logs.forEach((log) => {
        console.log(" New entry:", log.args);
      });
    },
  });

  return <div>Listening for raffle entries...</div>;
}
```

If `amount` were indexed → you could filter by it too, but remember only **3 params can be indexed**.

---

### 🔹 Best practice

* Index **identifiers**: e.g. `address`, `id`, `round`
* Don’t index large data like `string` or `bytes` (costly in gas)
* Use non-indexed params for values you’ll usually just *read*, not *filter by*

---

## block.timestamp

```bash
// In constructor: s_lastTimeStamp = block.timestamp;
// This locks in the deployment timestamp as the starting point. So s_lastTimeStamp is “when the raffle opened.”

bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
```

So, let say i_interval be 1000 seconds. 
- At block.timestamp (1550) - s_lastTimeStamp (1000) = 550 seconds (timePassed False -> not triggering Upkeep)
- At block.timestamp (2550) - s_lastTimeStamp (1000) = 1550 seconds (timePassed True -> triggering Upkeep)

After upkeep runs, you reset:
`s_lastTimeStamp = block.timestamp;`