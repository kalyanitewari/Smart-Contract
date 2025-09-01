// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TradeEscrow {
    enum State { None, PaymentHeld, Shipped, Delivered, Completed, Disputed, Cancelled }

    struct Trade {
        address buyer;
        address seller;
        address verifier; // may be the seller or a third party
        uint256 amount;   // escrowed ETH
        bytes32 expectedDocHash;
        bool docSet;
        bool docVerified;
        State state;
    }

    address public immutable arbiter; // trusted third party for disputes
    uint256 public nextId;
    mapping(uint256 => Trade) public trades;

    bool private locked;
    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyBuyer(uint256 id){ require(msg.sender == trades[id].buyer, "Not buyer"); _; }
    modifier onlySeller(uint256 id){ require(msg.sender == trades[id].seller, "Not seller"); _; }
    modifier onlyVerifier(uint256 id){ require(msg.sender == trades[id].verifier, "Not verifier"); _; }
    modifier onlyArbiter(){ require(msg.sender == arbiter, "Not arbiter"); _; }
    modifier inState(uint256 id, State s){ require(trades[id].state == s, "Bad state"); _; }

    event TradeCreated(uint256 indexed id, address indexed buyer, address indexed seller, address verifier, uint256 amount);
    event Deposited(uint256 indexed id, uint256 amount);
    event DocumentHashSet(uint256 indexed id, bytes32 expectedDocHash);
    event DocumentVerified(uint256 indexed id, bytes32 providedHash);
    event Shipped(uint256 indexed id);
    event Delivered(uint256 indexed id);
    event PaymentReleased(uint256 indexed id, address to, uint256 amount);
    event Refunded(uint256 indexed id, address to, uint256 amount);
    event DisputeRaised(uint256 indexed id, address by, string reason);
    event DisputeResolved(uint256 indexed id, bool releasedToSeller);

    constructor(address _arbiter){ require(_arbiter != address(0), "arbiter=0"); arbiter = _arbiter; }

    /// Buyer creates the trade and deposits funds in one step
    function createTrade(address seller, address verifier, string calldata details)
        external
        payable
        returns (uint256 id)
    {
        require(seller != address(0), "seller=0");
        require(verifier != address(0), "verifier=0");
        require(msg.value > 0, "no funds");
        id = nextId++;
        trades[id] = Trade({
            buyer: msg.sender,
            seller: seller,
            verifier: verifier,
            amount: msg.value,
            expectedDocHash: bytes32(0),
            docSet: false,
            docVerified: false,
            state: State.PaymentHeld
        });
        emit TradeCreated(id, msg.sender, seller, verifier, msg.value);
        emit Deposited(id, msg.value);
        // 'details' is emitted off-chain via tx input; not stored on-chain to save gas
    }

    /// Seller specifies the document hash they expect to be verified (e.g., Bill of Lading)
    function setExpectedDocumentHash(uint256 id, bytes32 expectedDocHash)
        external
        onlySeller(id)
        inState(id, State.PaymentHeld)
    {
        trades[id].expectedDocHash = expectedDocHash;
        trades[id].docSet = true;
        emit DocumentHashSet(id, expectedDocHash);
    }

    /// Verifier (seller or third-party) confirms the provided document by matching the hash
    function verifyDocument(uint256 id, bytes32 providedHash)
        external
        onlyVerifier(id)
        inState(id, State.PaymentHeld)
    {
        Trade storage t = trades[id];
        require(t.docSet, "doc not set");
        require(providedHash == t.expectedDocHash, "hash mismatch");
        t.docVerified = true;
        emit DocumentVerified(id, providedHash);
        _trySettle(id);
    }

    /// Seller marks shipment dispatched
    function markShipped(uint256 id)
        external
        onlySeller(id)
        inState(id, State.PaymentHeld)
    {
        trades[id].state = State.Shipped;
        emit Shipped(id);
    }

    /// Buyer confirms delivery
    function confirmDelivered(uint256 id)
        external
        onlyBuyer(id)
    {
        Trade storage t = trades[id];
        require(t.state == State.Shipped || t.state == State.PaymentHeld, "bad state");
        t.state = State.Delivered;
        emit Delivered(id);
        _trySettle(id);
    }

    /// Either party can raise a dispute (arbiter will resolve)
    function raiseDispute(uint256 id, string calldata reason) external {
        Trade storage t = trades[id];
        require(msg.sender == t.buyer || msg.sender == t.seller, "not party");
        require(t.state != State.Completed && t.state != State.Cancelled, "finalized");
        t.state = State.Disputed;
        emit DisputeRaised(id, msg.sender, reason);
    }

    /// Arbiter decides outcome: release to seller or refund buyer
    function resolveDispute(uint256 id, bool releaseToSeller)
        external
        onlyArbiter
        nonReentrant
    {
        Trade storage t = trades[id];
        require(
            t.state == State.Disputed || t.state == State.PaymentHeld || t.state == State.Shipped || t.state == State.Delivered,
            "bad state"
        );
        uint256 amount = t.amount;
        t.amount = 0;
        t.state = State.Completed;
        if (releaseToSeller) {
            (bool ok,) = t.seller.call{value: amount}("");
            require(ok, "send fail");
            emit PaymentReleased(id, t.seller, amount);
            emit DisputeResolved(id, true);
        } else {
            (bool ok,) = t.buyer.call{value: amount}("");
            require(ok, "send fail");
            emit Refunded(id, t.buyer, amount);
            emit DisputeResolved(id, false);
        }
    }

    /// Buyer can cancel and get a refund any time BEFORE the seller marks shipped
    function cancelBeforeShipment(uint256 id)
        external
        onlyBuyer(id)
        inState(id, State.PaymentHeld)
        nonReentrant
    {
        Trade storage t = trades[id];
        uint256 amount = t.amount;
        t.amount = 0;
        t.state = State.Cancelled;
        (bool ok,) = t.buyer.call{value: amount}("");
        require(ok, "refund fail");
        emit Refunded(id, t.buyer, amount);
    }

    /// Internal auto-settlement once both docVerified & Delivered are true
    function _trySettle(uint256 id) internal nonReentrant {
        Trade storage t = trades[id];
        if (t.docVerified && (t.state == State.Delivered)) {
            uint256 amount = t.amount;
            t.amount = 0;
            t.state = State.Completed;
            (bool ok,) = t.seller.call{value: amount}("");
            require(ok, "release fail");
            emit PaymentReleased(id, t.seller, amount);
        }
    }

    /// Helper so you can compute the bytes32 hash for a document string right in Remix
    function hashString(string calldata s) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(s));
    }

    /// Quick view helper for Remix
    function getTrade(uint256 id) external view returns (
        address buyer, address seller, address verifier, uint256 amount,
        bytes32 expectedDocHash, bool docVerified, State state
    ) {
        Trade storage t = trades[id];
        return (t.buyer, t.seller, t.verifier, t.amount, t.expectedDocHash, t.docVerified, t.state);
    }

    receive() external payable {}
}
