// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SimpleAccount
 * @dev A minimal ERC-4337 compliant smart contract account
 * Features:
 * - Single owner authorization
 * - ECDSA signature verification
 * - UUPS upgradeable
 * - Can execute transactions and batch transactions
 */
contract SimpleAccount is BaseAccount, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public owner;
    IEntryPoint private immutable _entryPoint;

    event SimpleAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "SimpleAccount: not owner");
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    /**
     * @dev Initialize the account with an owner
     * @param anOwner The owner address
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        require(anOwner != address(0), "SimpleAccount: owner cannot be zero address");
        owner = anOwner;
        emit SimpleAccountInitialized(_entryPoint, owner);
    }

    /**
     * @dev Execute a transaction (called by entryPoint or owner)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * @dev Execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length && dest.length == value.length, "SimpleAccount: wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], value[i], func[i]);
        }
    }

    /**
     * @dev Validate signature for a user operation
     * @param userOp The user operation
     * @param userOpHash The hash of the user operation
     * @return validationData 0 if valid, 1 if invalid
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * @dev Transfer ownership of the account
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SimpleAccount: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * @dev Deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * @dev Withdraw value from the account's deposit
     * @param withdrawAddress Target to send to
     * @param amount Amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _requireFromEntryPointOrOwner();
    }

    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner, "SimpleAccount: not owner or entryPoint"
        );
    }
}
