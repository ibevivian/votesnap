# Snapshot Voting System

A decentralized voting system built on Stacks blockchain using Clarity smart contracts. This system captures token balances at specific block heights to ensure fair and transparent governance decisions.

## 🎯 Overview

The Snapshot Voting System allows token holders to participate in governance by voting on proposals. The system captures voting power at the time of proposal creation (snapshot), preventing manipulation through token transfers after proposal announcement.

## ✨ Key Features

- **Snapshot-Based Voting**: Captures token balances at proposal creation time
- **Flexible Proposal System**: Customizable voting periods and delays
- **Anti-Manipulation**: Prevents vote buying and last-minute token accumulation
- **Comprehensive Security**: Input validation and emergency controls
- **Transparent Results**: Real-time vote tracking and result calculation
- **Admin Controls**: Owner can manage system parameters and handle emergencies

## 🏗️ Architecture

### Core Components

1. **Proposals**: Store voting parameters, descriptions, and results
2. **Snapshot Balances**: Historical token balances at proposal creation
3. **Vote Records**: Individual vote choices and voting power
4. **Admin Functions**: System management and emergency controls

### Data Structures

```clarity
;; Proposal Structure
{
  title: (string-ascii 100),
  description: (string-ascii 500),
  creator: principal,
  snapshot-block: uint,
  start-block: uint,
  end-block: uint,
  yes-votes: uint,
  no-votes: uint,
  total-votes: uint,
  is-active: bool
}

;; Vote Record
{
  vote: bool,
  voting-power: uint,
  vote-block: uint
}
```

## 🚀 Getting Started

### Prerequisites

- Stacks blockchain environment
- Clarinet for local development
- Token contract for voting power calculation

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd snapshot-voting-system
```

2. Install Clarinet (if not already installed):
```bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.8.0/clarinet-linux-x64.tar.gz | tar xz
```

3. Initialize the project:
```bash
clarinet new snapshot-voting
cd snapshot-voting
```

4. Add the contract to your `contracts/` directory

### Configuration

Before deployment, update the token contract reference in the `get-token-balance-at-block` function:

```clarity
(define-private (get-token-balance-at-block (account principal) (block-num uint))
  ;; Replace with your actual token contract
  (contract-call? 'YOUR-TOKEN-CONTRACT-ADDRESS.your-token get-balance account)
)
```

## 📋 Usage

### Creating a Proposal

```clarity
;; Create a new proposal
(contract-call? .snapshot-voting create-proposal
  "Proposal Title"
  "Detailed description of the proposal and what it aims to achieve"
  u1440  ;; voting duration in blocks (~10 days)
  u144   ;; voting delay in blocks (~1 day)
)
```

### Recording Snapshot Balance

Before voting, users must record their balance at the snapshot block:

```clarity
(contract-call? .snapshot-voting record-snapshot-balance
  u1  ;; proposal-id
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; voter address
)
```

### Casting a Vote

```clarity
;; Vote YES on proposal
(contract-call? .snapshot-voting cast-vote u1 true)

;; Vote NO on proposal
(contract-call? .snapshot-voting cast-vote u1 false)
```

### Checking Results

```clarity
;; Get proposal details
(contract-call? .snapshot-voting get-proposal u1)

;; Get voting results
(contract-call? .snapshot-voting get-proposal-results u1)
```

## 🔧 API Reference

### Public Functions

#### `create-proposal`
Creates a new voting proposal.
- **Parameters**: `title`, `description`, `voting-duration`, `voting-delay`
- **Returns**: `(ok proposal-id)` or error
- **Access**: Anyone

#### `record-snapshot-balance`
Records a voter's token balance at snapshot time.
- **Parameters**: `proposal-id`, `voter`
- **Returns**: `(ok balance)` or error
- **Access**: Anyone

#### `cast-vote`
Submits a vote for a proposal.
- **Parameters**: `proposal-id`, `vote` (true/false)
- **Returns**: `(ok voting-power)` or error
- **Access**: Token holders with recorded balance

#### `end-proposal`
Manually ends a proposal before natural expiration.
- **Parameters**: `proposal-id`
- **Returns**: `(ok true)` or error
- **Access**: Proposal creator or contract owner

### Read-Only Functions

#### `get-proposal`
Retrieves proposal details.
- **Parameters**: `proposal-id`
- **Returns**: Proposal data or none

#### `get-vote`
Gets a specific vote record.
- **Parameters**: `proposal-id`, `voter`
- **Returns**: Vote data or none

#### `get-proposal-results`
Calculates and returns voting results.
- **Parameters**: `proposal-id`
- **Returns**: Results summary with vote counts

#### `is-voting-active`
Checks if voting is currently active for a proposal.
- **Parameters**: `proposal-id`
- **Returns**: `true` or `false`

### Admin Functions (Owner Only)

#### `set-min-voting-power`
Updates minimum required voting power.
- **Parameters**: `new-min`

#### `set-token-contract`
Updates the token contract used for balance checking.
- **Parameters**: `new-contract`

#### `emergency-deactivate`
Emergency function to deactivate any proposal.
- **Parameters**: `proposal-id`

## 🛡️ Security Features

### Input Validation
- Non-empty titles and descriptions
- Reasonable voting duration limits (max ~100 days)
- Positive numerical values with upper bounds
- Valid proposal ID checks

### Anti-Manipulation
- Snapshot-based voting prevents token accumulation after proposal
- One vote per address per proposal
- Minimum voting power requirements
- Historical balance verification

### Access Controls
- Owner-only admin functions
- Creator or owner can end proposals
- Emergency deactivation capabilities

### Error Handling
- Comprehensive error codes and messages
- Graceful failure modes
- Input sanitization

## 🧪 Testing

### Unit Tests

```bash
clarinet test
```

### Integration Tests

Test the complete voting flow:

1. Deploy contract
2. Create proposal
3. Record snapshot balances
4. Cast votes
5. Verify results

### Test Scenarios

- ✅ Successful proposal creation and voting
- ✅ Voting period enforcement
- ✅ Double voting prevention
- ✅ Insufficient balance handling
- ✅ Admin function access control
- ✅ Emergency deactivation

## 🚦 Deployment

### Testnet Deployment

```bash
clarinet deploy --testnet
```

### Mainnet Deployment

```bash
clarinet deploy --mainnet
```

### Post-Deployment Setup

1. Set the correct token contract address
2. Configure minimum voting power
3. Test with a sample proposal
4. Verify all functions work as expected

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure security considerations are addressed

## 📈 Roadmap

- [ ] Multi-choice voting support
- [ ] Quadratic voting implementation
- [ ] Delegation mechanisms
- [ ] Integration with popular token standards
- [ ] Web interface for easy interaction
- [ ] Advanced analytics and reporting


**Note**: This is a foundational implementation. Always conduct thorough security audits before using in production environments with significant value at stake.