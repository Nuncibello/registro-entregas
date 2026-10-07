// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title DeliveryRegistry
/// @author Bruno Nuncibello
/// @notice Timestamps a document on-chain so anyone can prove it existed, unchanged,
///         at a given moment. Only the hash is stored: the document never leaves the
///         author's machine.
/// @dev Writing is restricted to accounts the owner authorizes; reading is open to all.
///      Storage is packed so a record fits in two slots, and reverts use custom errors.
contract DeliveryRegistry {
    struct Delivery {
        uint64 timestamp;   // slot 0, packed with the author address
        address author;     // slot 0
        string label;   // slot 1
    }

    address public owner;
    uint256 public total;

    mapping(bytes32 => Delivery) private _deliveries;
    mapping(address => bool) public isWriter;

    event Registered(bytes32 indexed digest, address indexed author, uint64 timestamp, string label);
    event WriterUpdated(address indexed account, bool allowed);
    event OwnershipTransferred(address indexed from, address indexed to);

    error NotOwner();
    error NotWriter();
    error AlreadyRegistered();
    error EmptyDigest();
    error ZeroAddress();

    constructor() {
        owner = msg.sender;
        isWriter[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
        emit WriterUpdated(msg.sender, true);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Records the hash of a document. The same hash cannot be recorded twice.
    /// @param digest keccak256 of the file, computed off-chain.
    /// @param label Free text to recognize it later, for example an order number.
    function register(bytes32 digest, string calldata label) external {
        if (!isWriter[msg.sender]) revert NotWriter();
        if (digest == bytes32(0)) revert EmptyDigest();
        if (_deliveries[digest].timestamp != 0) revert AlreadyRegistered();

        uint64 at = uint64(block.timestamp);
        _deliveries[digest] = Delivery({timestamp: at, author: msg.sender, label: label});
        unchecked {
            ++total;
        }
        emit Registered(digest, msg.sender, at, label);
    }

    /// @notice Reads a record. Never reverts: an unknown hash returns exists = false.
    function verify(bytes32 digest)
        external
        view
        returns (bool exists, uint64 timestamp, address author, string memory label)
    {
        Delivery storage d = _deliveries[digest];
        return (d.timestamp != 0, d.timestamp, d.author, d.label);
    }

    /// @notice Grants or revokes permission to record documents.
    function setWriter(address account, bool allowed) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        isWriter[account] = allowed;
        emit WriterUpdated(account, allowed);
    }

    /// @notice Hands the contract over to another account, which keeps writing rights.
    function transferOwnership(address to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        address previous = owner;
        owner = to;
        isWriter[to] = true;
        emit OwnershipTransferred(previous, to);
        emit WriterUpdated(to, true);
    }
}
