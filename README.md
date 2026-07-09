# Escrow Contract in Solidity w/Yul
> A demonstration of writing an Escrow smart contract in pure Solidity versus using inline Yul assembly for gas optimization. This repo explores low-level EVM optimizations, inline assembly techniques, and the trade-offs between readability and efficiency in Solidity development.

## Table of Contents
- [Description](#description)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [What I Learned](#what-i-learned)
- [Gas Optimization](#gas-optimization)


## Description
This repository compares two implementations of a basic Escrow contract:

> Escrow.sol: A standard Solidity implementation for holding funds (e.g., ETH) until conditions are met, such as release by a buyer/seller or arbiter.

> Escrow_in_Yul.sol: The same logic rewritten with significant use of inline Yul assembly for lower-level control over memory, storage, and operations.

### Brief description of an Escrow contract:

An Escrow contract acts as a trusted intermediary in blockchain transactions. It holds funds (typically ETH or tokens) deposited by one party (e.g., a buyer) until predefined conditions are satisfied—such as confirmation of delivery or mutual agreement—before releasing them to the recipient (e.g., a seller). If conditions fail, it allows refunds. This pattern enhances trust in decentralized environments by mitigating risks like non-delivery or non-payment.

## Prerequisites

- Node.js: v26.x (Current) or v24.x (Active LTS)
- Hardhat: v3.9.0 (or compatible latest)

## Setup

- git clone ```https://github.com/boydjawun/Hardhat_Escrow.git```
- cd ```Hardhat_Escrow```
- Install Dependencies: ```npm install```
- Compile: ```npx hardhat compile```
- Test: ```npx hardhat test```


## What I Learned

**Inline Yul Assembly for Performance:** Using Yul allows direct EVM opcode manipulation, reducing overhead from Solidity's high-level abstractions (e.g., safer but costlier memory handling and checks).

**Gas Optimization Techniques:** Key savings come from custom memory management, avoiding unnecessary SLOAD/SSTORE, and minimizing compiler-generated safety checks—while carefully managing security risks like reentrancy.

**Trade-offs in Smart Contract Development:** High-level Solidity improves readability and auditability, but low-level Yul unlocks significant gas efficiency for production contracts where deployment and execution costs matter.

## Gas Optimization

I measured the standard Solidity implementation using Hardhat's gas reporting tools. Here are the results for `Escrow.sol`:

![Solidity Gas Report](https://github.com/boydjawun/Hardhat_Escrow/blob/main/Gas_Report/Escrow_sol.png)

### Solidity Gas Usage (`Escrow.sol`)

| Function / Action     | Gas Cost   | Notes |
|-----------------------|------------|-------|
| **Deployment**        | 633,826    | Full contract deployment |
| `approve()`           | 54,411     | Arbiter releases funds |
| `refund()`            | 54,410     | Arbiter refunds depositor |
| `getBalance()`        | 21,399     | View current balance |
| Getter functions (`arbiter`, `beneficiary`, `depositor`) | ~21,400–21,500 | Public immutable getters |

**Bytecode size**: 2,638 bytes

### Why the Yul Version (`Escrow_in_Yul.sol`) is Cheaper

Even without running a new gas report, the inline Yul version uses **significantly less gas** due to these low-level optimizations:

1. **Direct EVM Opcodes**
   - Uses `selfbalance()` instead of `address(this).balance`
   - Raw `sload` / `sstore` for `isApproved` (slot 0)
   - Manual `call` with minimal overhead

2. **Reduced Safety & ABI Overhead**
   - Custom errors (4-byte selectors) instead of string messages
   - Manual `log1` for events instead of Solidity’s `emit`
   - No unnecessary memory copies or compiler-inserted checks

3. **Smaller Bytecode**
   - Less compiler-generated boilerplate → lower deployment cost


> The Yul version trades readability for efficiency. It demonstrates real-world techniques used in high-performance contracts (e.g., DEXes, lending protocols) where every gas unit matters.

**Recommendation**: Use pure Solidity for most projects. Drop into inline Yul (or full Yul) only for performance-critical sections after profiling.


Notes:
- Savings primarily from optimized storage access, reduced memory copies, and fewer runtime checks.
- Always test thoroughly—Yul increases complexity and potential for subtle bugs.
- Use Hardhat's gas reporter plugin for precise measurements.
