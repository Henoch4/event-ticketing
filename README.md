# Stubhouse — On-Chain Event Ticketing

> Stubhouse issues tickets as tokens with transferable and resale-controlled behavior. Organizers cap supply, gate transfers, and let the venue scan ownership straight from the chain instead of cursing QR codes.

## What it does

Stubhouse issues tickets as tokens with transferable and resale-controlled behavior. Organizers cap supply, gate transfers, and let the venue scan ownership straight from the chain instead of cursing QR codes. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/EventTicketing.sol` |
| Contract name | `EventTicketing` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 7 (of which 1 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `createEvent` | write | uint256 |
| `buyTicket` | payable | tx receipt |
| `completeEvent` | write | result / revert |
| `withdrawRevenue` | write | result / revert |
| `getEvent` | view | address organizer, string memory title, string memory description, uint256 totalTickets, uint256 soldTickets, uint256 price, uint256 startTime, uint256 endTime, bool active, bool completed |
| `getTicketBalance` | view | uint256 |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `EventCreated` | (uint256 indexed eid, address indexed organizer, string title, uint256 price, uint256 supply) |
| `TicketBought` | (uint256 indexed eid, address indexed buyer, uint256 qty, uint256 paid) |
| `EventCompleted` | (uint256 indexed eid, address indexed organizer) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/event-ticketing.git
cd event-ticketing
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.