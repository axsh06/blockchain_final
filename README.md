# 🚀 DeFi Super-App Protocol
**Blockchain Technologies 2 - Final Project (Option A)**

A production-grade, full-stack decentralized finance protocol deployed on **Arbitrum Sepolia L2**. This capstone project integrates a Constant-Product AMM, an ERC-4626 Tokenized Yield Vault, and a robust on-chain DAO governance system, complete with a React/Wagmi frontend and The Graph indexing.

## 👥 Team & Roles
* **Alisher** - Smart Contracts Core (AMM, ERC-4626 Vault, OpenZeppelin Governor stack, Invariant & Fuzz Testing)
* **Ramazan** - DevOps & Architecture (CI/CD pipelines, AMM Factory, Slither analysis, Coverage, Infrastructure)
* **Bekzat** - Frontend & Indexing (React UI, Wagmi/Viem Web3 integration, The Graph Subgraph, UX/UI logic)

---

## 🔗 Verified Smart Contracts (Arbitrum Sepolia)

All contracts have been successfully deployed and verified on the Arbitrum Sepolia L2 testnet. 

| Contract | Address | Explorer Link |
|----------|---------|---------------|
| **GovToken (ERC20Votes)** | `0x483cb804c71a02c340c73fb4d77b0a826fb38f15` | [View on Arbiscan](https://sepolia.arbiscan.io/address/0x483cb804c71a02c340c73fb4d77b0a826fb38f15) |
| **TimelockController** | `0xda057e419f19785ec96cc5d1a0bdf7d6a88e861d` | [View on Arbiscan](https://sepolia.arbiscan.io/address/0xda057e419f19785ec96cc5d1a0bdf7d6a88e861d) |
| **ProtocolGovernor** | `0xc872b9d674a33207de11794f32e66955a4517296` | [View on Arbiscan](https://sepolia.arbiscan.io/address/0xc872b9d674a33207de11794f32e66955a4517296) |
| **AMMPair** | `0xd85c4cf4be8841c26d92bb026c2e3f39c7216578` | [View on Arbiscan](https://sepolia.arbiscan.io/address/0xd85c4cf4be8841c26d92bb026c2e3f39c7216578) |
| **YieldVault (ERC-4626)** | `0x8fabb19d51ad8c0ea6e22d9d9b13f200adc16adf` | [View on Arbiscan](https://sepolia.arbiscan.io/address/0x8fabb19d51ad8c0ea6e22d9d9b13f200adc16adf) |

---

## 🛠️ Architecture & Features

* **Constant-Product AMM:** Implements the $x \cdot y = k$ formula with a 0.3% pool fee and slippage protection. Factory pattern utilized for pool deployment.
* **Tokenized Yield Vault:** Fully compliant with the ERC-4626 standard, protecting against inflation attacks and rounding errors.
* **DAO Governance:** Powered by OpenZeppelin's `Governor` and `TimelockController`. Features a 1-week voting period, 4% quorum, and a 2-day timelock delay for treasury actions.
* **Continuous Integration:** GitHub Actions automatically enforces `forge test`, `forge coverage`, `forge fmt`, and `Slither` static analysis on every pull request.

---

## 💻 Running the Project Locally

### 1. Smart Contracts (Foundry)
Ensure you have [Foundry](https://getfoundry.sh/) installed.
```shell
# Install submodules (OpenZeppelin, etc.)
git submodule update --init --recursive

# Compile contracts
forge build

# Run the test suite (Unit, Fuzz, Invariant)
forge test

```

### 2. Frontend (React + Vite)

Ensure you have [Node.js](https://nodejs.org/) installed.

```shell
cd frontend

# Install dependencies
npm install

# Start the development server
npm run dev

```

*Note: The frontend includes an automatic network detector. Ensure your MetaMask is set to **Arbitrum Sepolia**.*

---

## 📊 The Graph: GraphQL Queries

The protocol's events are indexed using a custom Subgraph. Below are the 5 core queries used to extract on-chain data into our frontend:

**1. Fetch the 5 most recent AMM swaps**

```graphql
query GetRecentSwaps {
  swaps(first: 5, orderBy: timestamp, orderDirection: desc) {
    id
    sender
    amountIn
  }
}

```

**2. Fetch all vault deposits for a specific user**

```graphql
query GetUserDeposits($user: Bytes!) {
  deposits(where: { owner: $user }) {
    assets
    timestamp
  }
}

```

**3. List all created DAO proposals**

```graphql
query GetProposals {
  proposalCreateds {
    proposalId
    proposer
    description
  }
}

```

**4. View the top 5 largest votes (Whales)**

```graphql
query GetWhaleVotes {
  voteCasts(first: 5, orderBy: weight, orderDirection: desc) {
    voter
    proposalId
    weight
  }
}

```

**5. View the complete voting history for a specific proposal**

```graphql
query GetVotesForProposal($proposal: BigInt!) {
  voteCasts(where: { proposalId: $proposal }) {
    voter
    support
    weight
  }
}

```