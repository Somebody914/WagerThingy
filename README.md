# Wager Platform - Verified Competitive Gaming Bets

A decentralized wager platform for competitive gaming with built-in verification and dispute resolution. Players can challenge each other with cryptocurrency stakes, submit proof of wins, and resolve disputes through an on-chain escrow system.

## Features

### 🎮 Game Account Linking
- Link gaming platform accounts (Riot Games, Steam, Epic Games, Battle.net, Xbox Live, PlayStation Network)
- Verify account ownership through profile bio verification
- Required platform accounts are enforced for game selection
- Supports games: Valorant, League of Legends, CS2, Fortnite, Dota 2, and more

### 📸 Proof Submission System
- Winner submits screenshot proof after match completion
- Drag-and-drop file upload (PNG/JPG, max 10MB)
- Optional match ID and notes
- Screenshots uploaded to IPFS (simulated with fake hash for demo)
- Proof hash stored on-chain via `submitProof()` function

### ⚖️ Dispute Resolution
- 24-hour dispute window after proof submission
- Predefined dispute reasons:
  - Screenshot is fake or edited
  - Screenshot is from a different match
  - I actually won this match
  - Opponent cheated during match
  - Other reason
- Disputer must provide counter-evidence and explanation
- Admin reviews both sides and resolves via `resolveDispute()`

### 💰 Escrow & Payouts
- Funds held in smart contract escrow
- 3% platform fee on total pot
- Winner claims funds after 24h if no dispute via `claimAfterTimeout()`
- Disputed wagers resolved by admin via `resolveDispute()`
- Automatic payout calculation and distribution

### 🔐 Security Features
- Wallet-based authentication via MetaMask
- Smart contract holds all funds in escrow
- Time-locked dispute windows
- Admin-only dispute resolution
- On-chain event logging for transparency

## How It Works

### 1. Create a Wager
1. Connect your MetaMask wallet
2. Link required gaming platform account in the "Accounts" tab
3. Select "Direct Challenge" (specific opponent) or "Open Challenge" (anyone)
4. Choose a game from the list (only games with linked platform accounts are available)
5. Enter wager amount in ETH
6. Submit transaction to create wager

### 2. Accept a Wager
1. Browse "Active Wagers" tab
2. Click on a wager to view details
3. Click "Accept Wager" and match the stake
4. Transaction creates escrow with both stakes locked

### 3. Play the Match
- Complete your match on the gaming platform
- Winner prepares screenshot of final results

### 4. Submit Proof of Win
1. Click "Submit Win Proof" on the wager
2. Upload screenshot showing match result
3. Optionally add match ID and notes
4. Submit proof (uploaded to IPFS and hash stored on-chain)

### 5. Dispute Window (24 hours)
- Opponent can view submitted proof
- If proof is incorrect, opponent can dispute within 24 hours
- Dispute requires:
  - Selection of dispute reason
  - Counter-evidence screenshot
  - Written explanation

### 6. Resolution
**If No Dispute:**
- After 24 hours, winner calls `claimAfterTimeout()`
- Funds automatically distributed (pot minus 3% fee)

**If Disputed:**
- Admin reviews both sides' evidence
- Admin calls `resolveDispute(wagerId, winnerAddress)`
- Funds distributed to determined winner

## Gaming Account Linking

### Supported Platforms

| Platform | Games | Verification Method |
|----------|-------|---------------------|
| **Riot Games** | Valorant, League of Legends | Riot ID verification via profile bio |
| **Steam** | CS2, Dota 2, Rocket League | Steam profile URL verification |
| **Epic Games** | Fortnite, Rocket League | Epic Display Name verification |
| **Battle.net** | Overwatch 2, Call of Duty | BattleTag verification |
| **Xbox Live** | Cross-platform titles | Gamertag verification |
| **PlayStation Network** | Cross-platform titles | PSN Online ID verification |

### Linking Process

1. Navigate to "Accounts" tab
2. Click "Link" on desired platform
3. Enter your username/ID
4. Copy the verification code (e.g., `WAGER-ABC12`)
5. Add code to your platform profile bio
6. Click "Verify & Link"
7. System checks for code in your profile
8. Account is marked as verified

**Note:** In production, this would use official platform APIs. For demo purposes, verification is simulated and accounts are stored in localStorage.

## Smart Contract

### Deployment

1. Compile the contract:
```bash
solc --optimize --bin --abi contracts/WagerBook.sol -o build/
```

2. Deploy to Sepolia testnet:
```javascript
// Using ethers.js v6
const WagerBook = await ethers.getContractFactory("WagerBook");
const feeRecipient = "0xYourFeeRecipientAddress";
const wagerBook = await WagerBook.deploy(feeRecipient);
await wagerBook.waitForDeployment();
console.log("WagerBook deployed to:", await wagerBook.getAddress());
```

3. Update `CONTRACT_ADDRESS` in `index.html` with deployed address

### Contract Functions

#### User Functions
- `createWager(address opponent, string gameId)` - Create new wager
- `acceptWager(uint256 id)` - Accept and match stake
- `submitProof(uint256 id, string proofHash)` - Submit win proof
- `dispute(uint256 id, string reason, string evidenceHash)` - Dispute proof
- `claimAfterTimeout(uint256 id)` - Claim winnings after 24h
- `cancel(uint256 id)` - Cancel open wager (creator only)

#### Admin Functions
- `resolveDispute(uint256 id, address winner)` - Resolve disputed wager

#### View Functions
- `getWager(uint256 id)` - Get wager details
- `wagers(uint256 id)` - Direct struct access
- `nextId()` - Next wager ID
- `DISPUTE_WINDOW()` - Dispute window duration (24 hours)
- `FEE_BPS()` - Platform fee in basis points (300 = 3%)

### Events
```solidity
event WagerCreated(uint256 id, address indexed creator, address indexed opponent, uint256 amount, string gameId);
event WagerAccepted(uint256 id, address indexed accepter);
event ProofSubmitted(uint256 id, address indexed claimant, string proofHash);
event WagerDisputed(uint256 id, address indexed disputer, string reason);
event WagerResolved(uint256 id, address winner, uint256 payout);
event WagerCancelled(uint256 id);
```

## Technical Stack

### Frontend
- **HTML/CSS/JavaScript** - Vanilla implementation, no framework
- **ethers.js v6** - Ethereum blockchain interaction
- **Web3 Provider** - MetaMask for wallet connection

### Smart Contract
- **Solidity ^0.8.19** - Contract language
- **Sepolia Testnet** - Default deployment target (chain ID 11155111)

### Storage (Demo)
- **localStorage** - Gaming account links (production would use backend database)
- **IPFS** - Screenshot storage (simulated with fake hash for demo)

## File Structure

```
/
├── index.html          # Complete frontend application
├── contracts/
│   └── WagerBook.sol   # Smart contract
└── README.md           # This file
```

## Running Locally

1. Clone the repository:
```bash
git clone https://github.com/Somebody914/WagerThingy.git
cd WagerThingy
```

2. Open `index.html` in a web browser

3. Ensure MetaMask is installed and connected to Sepolia testnet

4. Deploy smart contract and update `CONTRACT_ADDRESS` in index.html

5. Get Sepolia ETH from faucet: https://sepoliafaucet.com/

6. Start creating and accepting wagers!

## Security Considerations

### Smart Contract Security
- ✅ Reentrancy protection via state updates before transfers
- ✅ Access control with admin-only functions
- ✅ Time-locked dispute windows prevent premature claims
- ✅ Input validation on all functions
- ✅ Events for transparency and off-chain monitoring

### Frontend Security
- ⚠️ Gaming account verification is simulated (production needs backend)
- ⚠️ IPFS upload is simulated (production needs Pinata/Web3.Storage)
- ⚠️ Admin key management needed for dispute resolution
- ⚠️ Consider multi-sig for admin functions in production

### Production Recommendations
1. **Backend API** for gaming account verification
2. **Real IPFS integration** with pinning service
3. **Multi-signature admin** for dispute resolution
4. **Oracle integration** for automated match result verification where possible
5. **Insurance fund** for exceptional dispute cases
6. **Rate limiting** on proof submissions
7. **Image verification** to detect fake/edited screenshots
8. **KYC/Compliance** for large wagers

## Gas Optimization

The contract is optimized for gas efficiency:
- Structs packed to minimize storage slots
- Events instead of view functions where appropriate
- Batch reads where possible
- Single storage updates per transaction

## Testing

### Manual Testing Checklist
- [ ] Connect wallet to Sepolia
- [ ] Link gaming platform account
- [ ] Create direct challenge wager
- [ ] Create open challenge wager
- [ ] Accept wager from another account
- [ ] Submit proof of win
- [ ] Dispute proof submission
- [ ] Claim after timeout (no dispute)
- [ ] Admin resolve dispute

### Smart Contract Testing
```bash
# Using Hardhat
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat test
```

## Troubleshooting

### "Wrong network" error
- Ensure MetaMask is connected to Sepolia testnet (Chain ID: 11155111)
- Switch networks in MetaMask

### "Please install MetaMask" error
- Install MetaMask browser extension
- Refresh the page

### "Transaction failed" error
- Check you have sufficient Sepolia ETH for gas
- Ensure wager amounts match exactly when accepting
- Verify dispute window is still open

### "Link account first" error
- Navigate to Accounts tab
- Link required platform account for selected game

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Support

For issues or questions:
- Open a GitHub issue
- Contact: [Your contact information]

## Disclaimer

This is a demo/educational project. Use at your own risk. Always verify smart contracts before depositing funds. Gaming involves risk, gamble responsibly.
