// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Simple Escrow Contract
 * @notice A basic escrow where a depositor locks funds that can only be released
 *         by a trusted arbiter to the beneficiary. This is for learning purposes.
 *
 * Key Security Features & Lessons:
 * - Role-based access control (only arbiter can release funds)
 * - Single-use approval (prevents double-spending the same funds)
 * - Checks-Effects-Interactions pattern (minimize reentrancy risk)
 * - Explicit failure handling on external calls
 * - Events for transparency and off-chain monitoring
 * - No selfdestruct or delegatecall to reduce attack surface
 */
contract Escrow {
    address public immutable depositor;   // The party who deposits the funds (set once at deployment)
    address public immutable beneficiary; // The party who will receive the funds upon approval
    address public immutable arbiter;     // Trusted third party who decides when to release funds

    bool public isApproved;               // Prevents multiple approvals / releases

    /**
     * @dev Emitted when the arbiter approves and funds are released
     */
    event Approved(uint256 amount);

    /**
     * @dev Emitted when the arbiter refunds the depositor (added for better functionality)
     */
    event Refunded(uint256 amount);

    /**
     * @notice Constructor sets up the escrow with a one-time deposit
     * @param _beneficiary The address that will receive the funds if approved
     * @param _arbiter The trusted arbiter who controls release/refund
     *
     * Security note: Constructor is payable so the depositor can send ETH immediately.
     * Using `immutable` saves gas and prevents anyone from changing roles after deployment.
     */
    constructor(address _beneficiary, address _arbiter) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(msg.value > 0, "Must deposit some Ether");

        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
    }

    /**
     * @dev Modifier to restrict functions to the arbiter only and ensure it hasn't been used yet
     * Protection: Prevents unauthorized parties from releasing funds and stops replay attacks
     */
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only the arbiter can call this function");
        require(!isApproved, "Escrow has already been resolved");
        _;
    }

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

        //=== CHECK ===
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to release");

        //=== EFFECT ===
        isApproved = true;   // Effect: mark as resolved 

        //=== Interaction ===
        (bool sent, ) = payable(beneficiary).call{value: balance}(""); //Send funds to benficiary
        require(sent, "Failed to send Ether to beneficiary");

        //=== EFFECT ===
        emit Approved(balance);
    }

    /**
     * @notice Allows the arbiter to refund all funds back to the depositor
     * @dev Added for a complete escrow (original version lacked dispute handling)
     *
     * This protects the depositor if the beneficiary doesn't fulfill their part of the deal.
     */
    function refund() external onlyArbiter {
        isApproved = true;                    // Effect: mark as resolved

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to refund");

        // Interaction: send funds back to depositor
        (bool sent, ) = payable(depositor).call{value: balance}("");
        require(sent, "Failed to refund Ether to depositor");

        emit Refunded(balance);
    }

    /**
     * @notice View function to check current balance (useful for frontend/off-chain apps)
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
