# 🏛️ Physical Asset Tokenization System

> Transform real-world assets into tradeable blockchain tokens with STX-backed smart contracts

## 🌟 Overview

The Physical Asset Tokenization System bridges traditional physical assets with blockchain technology, enabling secure tokenization, fractional ownership, and global trading of real-world items like cars, gold, artwork, and more.

## ✨ Key Features

- 🔐 **Secure Asset Registration** - Register physical assets with metadata
- 🎯 **Oracle Verification** - Third-party validation of asset ownership and value
- 💎 **Fractional Ownership** - Split assets into tradeable tokens
- 💰 **Decentralized Trading** - Buy/sell tokens without intermediaries
- 🛡️ **Access Controls** - Role-based permissions for oracles and owners
- 📊 **Platform Fees** - Configurable transaction fees

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Stacks Wallet](https://www.hiro.so/wallet) or compatible wallet

### Installation

```bash
git clone <repository-url>
cd Physical-Asset-Tokenization-System
clarinet check
```

## 📋 Contract Functions

### 🔧 Admin Functions

#### `authorize-oracle`
Authorize a principal to act as an oracle for asset verification.
```clarity
(contract-call? .Physical-Asset-Tokenization-System authorize-oracle 'SP1234567890...)
```

#### `revoke-oracle`
Remove oracle authorization from a principal.
```clarity
(contract-call? .Physical-Asset-Tokenization-System revoke-oracle 'SP1234567890...)
```

#### `set-platform-fee`
Set platform trading fee (in basis points, max 1000 = 10%).
```clarity
(contract-call? .Physical-Asset-Tokenization-System set-platform-fee u50)
```

### 🏗️ Asset Management

#### `register-asset`
Register a new physical asset for tokenization.
```clarity
(contract-call? .Physical-Asset-Tokenization-System register-asset 
  "Vintage Car 1969" 
  "Classic muscle car in excellent condition" 
  "Automotive" 
  u1000 
  u50000)
```

Parameters:
- `name`: Asset name (max 50 chars)
- `description`: Asset description (max 200 chars)
- `category`: Asset category (max 20 chars)
- `total-tokens`: Number of tokens to create
- `token-price`: Price per token in STX

#### `verify-asset`
Oracle verification of asset authenticity and value.
```clarity
(contract-call? .Physical-Asset-Tokenization-System verify-asset u1 'SP-ORACLE...)
```

### 💸 Token Operations

#### `transfer-tokens`
Transfer tokens between principals.
```clarity
(contract-call? .Physical-Asset-Tokenization-System transfer-tokens u1 'SP-RECIPIENT... u100)
```

#### `list-tokens-for-sale`
List tokens on the marketplace.
```clarity
(contract-call? .Physical-Asset-Tokenization-System list-tokens-for-sale u1 u100 u55000)
```

#### `buy-tokens`
Purchase tokens from marketplace listings.
```clarity
(contract-call? .Physical-Asset-Tokenization-System buy-tokens u1 u50)
```

#### `cancel-listing`
Cancel an active marketplace listing.
```clarity
(contract-call? .Physical-Asset-Tokenization-System cancel-listing u1)
```

### 📖 Read-Only Functions

#### `get-asset`
Retrieve asset information by ID.
```clarity
(contract-call? .Physical-Asset-Tokenization-System get-asset u1)
```

#### `get-asset-tokens`
Get token balance for a specific holder and asset.
```clarity
(contract-call? .Physical-Asset-Tokenization-System get-asset-tokens u1 'SP-HOLDER...)
```

#### `get-asset-listing`
Get marketplace listing details.
```clarity
(contract-call? .Physical-Asset-Tokenization-System get-asset-listing u1)
```

## 🔄 Usage Workflow

1. **🏷️ Register Asset**: Owner registers physical asset with metadata
2. **✅ Oracle Verification**: Authorized oracle verifies asset authenticity
3. **💫 Token Creation**: System mints tokens representing fractional ownership
4. **🏪 Marketplace Listing**: Token holders list tokens for sale
5. **💳 Trading**: Users buy/sell tokens with STX payments
6. **🔄 Transfer**: Direct peer-to-peer token transfers

## 🛠️ Error Codes

| Code | Description |
|------|-------------|
| `u100` | Unauthorized access |
| `u101` | Asset not found |
| `u102` | Insufficient tokens |
| `u103` | Invalid amount |
| `u104` | Asset not verified |
| `u105` | Already exists |
| `u106` | Transfer failed |
| `u107` | Invalid price |

## 🧪 Testing

Run the test suite:
```bash
npm install
npm test
```

## 🔒 Security Features

- ✅ Oracle-based verification system
- ✅ Access control for sensitive operations
- ✅ Input validation and error handling
- ✅ Safe arithmetic operations
- ✅ Protection against common attacks

## 🌐 Use Cases

- 🚗 **Automotive**: Fractional car ownership and trading
- 💎 **Precious Metals**: Gold, silver, and commodity tokenization
- 🎨 **Art & Collectibles**: Fine art and rare item fractionalization
- 🏠 **Real Estate**: Property tokenization and investment
- 🏭 **Industrial Assets**: Equipment and machinery tokenization

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For questions and support, please open an issue in the repository.

---

Built with ❤️ using [Clarity](https://docs.stacks.co/clarity/) smart contracts on [Stacks](https://www.stacks.co/) 🚀
