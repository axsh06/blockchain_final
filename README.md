## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# 1. Получить последние 5 обменов в AMM
query GetRecentSwaps {
  swaps(first: 5, orderBy: timestamp, orderDirection: desc) {
    id
    sender
    amountIn
  }
}

# 2. Получить все депозиты конкретного пользователя в Vault
query GetUserDeposits($user: Bytes!) {
  deposits(where: { owner: $user }) {
    assets
    timestamp
  }
}

# 3. Получить список всех созданных предложений в DAO
query GetProposals {
  proposalCreateds {
    proposalId
    proposer
    description
  }
}

# 4. Посмотреть топ-5 крупных голосов в системе
query GetWhaleVotes {
  voteCasts(first: 5, orderBy: weight, orderDirection: desc) {
    voter
    proposalId
    weight
  }
}

# 5. Получить полную историю голосов по конкретному предложению
query GetVotesForProposal($proposal: BigInt!) {
  voteCasts(where: { proposalId: $proposal }) {
    voter
    support
    weight
  }
}