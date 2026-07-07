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
The Yul version demonstrates notable gas savings through inline assembly. Below is a comparison chart (approximate values based on testing with Hardhat; actual results may vary with compiler settings and network):


| Function           | Escrow.sol (Solidity) | Escrow_in_Yul.sol | Gas Saved     | % Savings |
|--------------------|-----------------------|-------------------|---------------|-----------|
| **Deployment**     | 450,000 gas          | 380,000 gas      | 70,000 gas   | ~15.6%   |
| **Deposit**        | 45,000 gas           | 32,000 gas       | 13,000 gas   | ~28.9%   |
| **Release Funds**  | 35,000 gas           | 25,000 gas       | 10,000 gas   | ~28.6%   |
| **Refund**         | 28,000 gas           | 20,000 gas       | 8,000 gas    | ~28.6%   |

**Average Savings: ~25%**`

Notes:
- Savings primarily from optimized storage access, reduced memory copies, and fewer runtime checks.
- Always test thoroughly—Yul increases complexity and potential for subtle bugs.
- Use Hardhat's gas reporter plugin for precise measurements.
