# 🌐 Virtual Reality Land Ownership Registry

A decentralized smart contract system for tokenizing and managing virtual reality land parcels with community-based governance and transfer restrictions. Built on the Stacks blockchain using Clarity.

## 🏗️ Overview

This smart contract enables secure property rights in metaverses by providing:

- 🏞️ **NFT-based Land Parcels**: Each VR land parcel is represented as a unique NFT with 3D coordinates
- 🏘️ **Community Governance**: Create communities with custom rules for land transfers
- ⭐ **Reputation System**: Member reputation tracking for community participation
- 🔒 **Transfer Restrictions**: Configurable rules based on reputation, cooldowns, and approvals
- 🏪 **Marketplace**: Built-in marketplace for buying and selling parcels
- 🛡️ **Lock Mechanism**: Owners can lock/unlock parcels to prevent unauthorized transfers

## 🚀 Core Features

### Land Parcel Management
- Mint new VR land parcels with 3D coordinates (x, y, z)
- Associate parcels with specific virtual worlds
- Track parcel size, creation timestamp, and community membership

### Community Governance
- Create communities with custom transfer rules
- Set minimum reputation requirements
- Configure transfer cooldowns and daily limits
- Optional approval-based transfers

### Reputation System
- Automatic reputation rewards for successful transactions
- Community-specific reputation tracking
- Reputation-based access control

### Marketplace
- List parcels for sale with expiration times
- Secure STX-based transactions
- Automatic ownership transfers

## 🔧 Installation & Setup

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) for testing

### Clone & Install
```bash
git clone <repository-url>
cd Virtual-Reality-Land-Ownership-Registry
npm install
```

### Deploy Contract
```bash
clarinet deploy --testnet
```

## 📋 Usage Guide

### 1. Creating a Community 🏘️

```clarity
(contract-call? .VR-Land-Registry create-community 
  "MetaWorld Builders"  ;; Community name
  u50                   ;; Minimum reputation required
  u1440                 ;; Transfer cooldown (blocks)
  u3                    ;; Max transfers per day
  false)                ;; Requires approval
```

### 2. Minting Land Parcels 🏞️

```clarity
(contract-call? .VR-Land-Registry mint-parcel
  100                   ;; X coordinate
  200                   ;; Y coordinate
  10                    ;; Z coordinate
  "MetaWorld"           ;; World ID
  u1000                 ;; Size
  u1001)                ;; Community ID
```

### 3. Transferring Parcels 🔄

```clarity
(contract-call? .VR-Land-Registry transfer-parcel
  u1                    ;; Parcel ID
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7) ;; Recipient
```

### 4. Marketplace Operations 🏪

**List a parcel for sale:**
```clarity
(contract-call? .VR-Land-Registry list-parcel
  u1                    ;; Parcel ID
  u1000000              ;; Price in microSTX
  u1440)                ;; Duration in blocks
```

**Buy a listed parcel:**
```clarity
(contract-call? .VR-Land-Registry buy-parcel
  u1)                   ;; Parcel ID
```

### 5. Security Features 🔒

**Lock a parcel:**
```clarity
(contract-call? .VR-Land-Registry lock-parcel u1)
```

**Unlock a parcel:**
```clarity
(contract-call? .VR-Land-Registry unlock-parcel u1)
```

## 🔍 Read-Only Functions

### Get Parcel Information
```clarity
(contract-call? .VR-Land-Registry get-parcel-info u1)
```

### Check Community Rules
```clarity
(contract-call? .VR-Land-Registry get-community-info u1001)
```

### View Member Reputation
```clarity
(contract-call? .VR-Land-Registry get-member-reputation u1001 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Check Marketplace Listings
```clarity
(contract-call? .VR-Land-Registry get-marketplace-listing u1)
```

## 🧪 Testing

Run the test suite:
```bash
npm test
```

Check contract syntax:
```bash
clarinet check
```

## 🏗️ Contract Architecture

### Data Structures

- **`parcel-data`**: Maps parcel IDs to coordinate, world, and ownership data
- **`community-rules`**: Stores governance rules for each community
- **`member-reputation`**: Tracks reputation scores per community member
- **`marketplace-listings`**: Active marketplace listings with prices and expiration
- **`transfer-history`**: Daily transfer counts for rate limiting

### Key Functions

| Function | Purpose |
|----------|----------|
| `mint-parcel` | Create new VR land NFTs |
| `transfer-parcel` | Transfer ownership with community rules |
| `create-community` | Establish new governance communities |
| `list-parcel` / `buy-parcel` | Marketplace operations |
| `lock-parcel` / `unlock-parcel` | Security controls |

## 🔐 Security Features

- ✅ **Ownership Verification**: All transfers require proper ownership
- ✅ **Community Compliance**: Transfers must meet community requirements
- ✅ **Reputation Gating**: Minimum reputation requirements
- ✅ **Rate Limiting**: Daily transfer limits per parcel
- ✅ **Lock Mechanism**: Owner-controlled transfer prevention
- ✅ **Approval System**: Optional community leader approval

## 🌟 Use Cases

- 🏰 **Virtual World Development**: Collaborative building with property rights
- 🎮 **Gaming Ecosystems**: In-game land ownership with real value
- 🏘️ **Metaverse Communities**: Governed virtual neighborhoods
- 💼 **Digital Real Estate**: Investment and trading in virtual properties
- 🎨 **Creative Spaces**: Artist galleries and exhibition spaces

## 🚀 Future Enhancements

- 🏠 Building and structure tracking
- 🌍 Multi-world support with cross-world transfers
- 🏆 Achievement-based reputation bonuses
- 📊 Analytics dashboard for community health
- 🔗 Integration with VR platforms

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 🆘 Support

For questions or issues, please open a GitHub issue or contact the development team.

---

*Built with ❤️ for the metaverse community*

# Virtual Reality Land Ownership Registry

