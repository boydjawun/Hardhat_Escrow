# Escrow Contract in Solidity w/Yul
> A demonstration of writing an Escrow smart contract in pure Solidity versus using inline Yul assembly for gas optimization. This repo explores low-level EVM optimizations, inline assembly techniques, and the trade-offs between readability and efficiency in Solidity development.

## Table of Contents
- [Description](#description)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [What I Learned](#what-i-learned)
- [Gas Optimization](#gas-optimization)
- [Check-Effect-Interactions](#check-effect-interactions)


## Description
This repository compares two implementations of a basic Escrow contract:

> [Escrow.sol](https://github.com/boydjawun/Hardhat_Escrow/blob/main/contracts/Escrow.sol): A standard Solidity implementation for holding funds (e.g., ETH) until conditions are met, such as release by a buyer/seller or arbiter.

> [Escrow_in_Yul.sol](https://github.com/boydjawun/Hardhat_Escrow/blob/main/EscrowYul/Escrow_in_Yul.sol): The same logic rewritten with significant use of inline Yul assembly for lower-level control over memory, storage, and operations.

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

## Check-Effect-Interactions
>Check-Effects-Interactions (CEI) is a key security pattern used when writing smart contracts (especially in Solidity) to prevent reentrancy attacks

1. First Check, validating conditions like require(balance > 0, "No funds to release") so the function fails fast.
2. Then Effects, updating internal state such as isApproved = true before touching the outside world
3. Finally Interactions, making external calls like (bool sent, ) = payable(beneficiary).call{value: balance}("") paired with require(sent, "Failed to send Ether to beneficiary"), since this is the point where control leaves the contract and a malicious receiver could attempt to re-enter.
   
### Solidity approve() function
```
/**
     * @notice Allows the arbiter to approve the release of all funds to the beneficiary
     * @dev Uses Checks-Effects-Interactions to reduce reentrancy risk
     *
     * Security considerations:
     * - State is updated BEFORE external call (Effects)
     * - Uses low-level call with value for flexibility (recipient could be a contract)
     * - Checks the return value to ensure transfer succeeded
     */

function approve() external onlyArbiter {

    // === CHECK ===
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to release");

    // === EFFECT ===
    isApproved = true; // Effect: update internal state before external call

    // === INTERACTION ===
    // Interaction: send funds to beneficiary
    (bool sent, ) = payable(beneficiary).call{value: balance}("");
    require(sent, "Failed to send Ether to beneficiary");

    // === EFFECT (Event emission) ===
    emit Approved(balance);
}
```
### Solidity w/Yul approve() function
>This contract uses a slightly non-canonical ordering, but preserves the core security guarantee CEI is meant to provide: no interaction happens until the resolved-state effect is locked in.

```
/**
 Selector & Topic0 Reference (keccak256-derived)

* Custom Error Selectors (first 4 bytes of keccak256(signature)):
    *   ZeroAddress()      -> 0xd92e233d
    *   ZeroDeposit()      -> 0x56316e87
    *   NotArbiter()       -> 0xccb665a6
    *   AlreadyResolved()  -> 0x6d5703c2
    *   NoFunds()          -> 0x43f9e110
    *   TransferFailed()   -> 0x90b8ec18

* Event Topic0s (full 32-byte keccak256(signature), used as topic0 in logs):
    *   Approved(uint256) -> 0x3ad93af63cb7967b23e4fb500b7d7d28b07516325dcf341f88bebf959d82c1cb
    *   Refunded(uint256) -> 0x3d2a04f53164bedf9a8a46353305d6b2d2261410406df3b41f99ce6489dc003c
*/
function approve() external {
    address _arbiter = arbiter;

    assembly {
        // Check: only arbiter can call
        if iszero(eq(caller(), _arbiter)) {
            mstore(0x00, 0xccb665a600000000000000000000000000000000000000000000000000000000)
            revert(0x00, 0x04) // NotArbitrator()
        }

        // Check: escrow not already resolved
        if sload(0) {
            mstore(0x00, 0x6d5703c200000000000000000000000000000000000000000000000000000000)
            revert(0x00, 0x04) // AlreadyResolved()
        }

        // Effect: mark resolved before balance check / external call
        sstore(0, 1)

        // Check: contract must hold funds to release
        let bal := selfbalance()
        if iszero(bal) {
            mstore(0x00, 0x43f9e11000000000000000000000000000000000000000000000000000000000)
            revert(0x00, 0x04) // NoFundsToRelease()
        }
    }

    address _beneficiary = beneficiary;

    assembly {
        // Interaction: send balance to beneficiary
        let bal := selfbalance()
        let sent := call(gas(), _beneficiary, bal, 0, 0, 0, 0)

        if iszero(sent) {
            mstore(0x00, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
            revert(0x00, 0x04) // TransferFailed()
        }

        // Effect: emit Approved(balance)
        mstore(0x00, bal)
        log1(
            0x00,
            0x20,
            0x3ad93af63cb7967b23e4fb500b7d7d28b07516325dcf341f88bebf959d82c1cb
        )
    }
}
```
