// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WagerBook {
    enum Status { Open, Accepted, ProofSubmitted, Disputed, Resolved, Cancelled }
    
    struct Wager {
        address creator;
        address opponent;
        uint256 amount;
        Status status;
        string gameId;
        address claimant;
        string proofHash;
        uint256 proofTimestamp;
        bool disputed;
        string disputeReason;
        string disputeEvidenceHash;
    }
    
    uint256 public constant DISPUTE_WINDOW = 24 hours;
    uint256 public constant FEE_BPS = 300; // 3%
    address public feeRecipient;
    address public admin;
    uint256 public nextId;
    
    mapping(uint256 => Wager) public wagers;
    
    event WagerCreated(uint256 id, address indexed creator, address indexed opponent, uint256 amount, string gameId);
    event WagerAccepted(uint256 id, address indexed accepter);
    event ProofSubmitted(uint256 id, address indexed claimant, string proofHash);
    event WagerDisputed(uint256 id, address indexed disputer, string reason);
    event WagerResolved(uint256 id, address winner, uint256 payout);
    event WagerCancelled(uint256 id);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    
    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
        admin = msg.sender;
    }
    
    function createWager(address opponent, string calldata gameId) external payable returns (uint256) {
        require(msg.value > 0, "Must send ETH");
        uint256 id = nextId++;
        wagers[id] = Wager({
            creator: msg.sender,
            opponent: opponent,
            amount: msg.value,
            status: Status.Open,
            gameId: gameId,
            claimant: address(0),
            proofHash: "",
            proofTimestamp: 0,
            disputed: false,
            disputeReason: "",
            disputeEvidenceHash: ""
        });
        emit WagerCreated(id, msg.sender, opponent, msg.value, gameId);
        return id;
    }
    
    function acceptWager(uint256 id) external payable {
        Wager storage w = wagers[id];
        require(w.status == Status.Open, "Not open");
        require(msg.value == w.amount, "Wrong amount");
        if (w.opponent != address(0)) {
            require(msg.sender == w.opponent, "Not invited");
        }
        w.opponent = msg.sender;
        w.status = Status.Accepted;
        emit WagerAccepted(id, msg.sender);
    }
    
    function submitProof(uint256 id, string calldata proofHash) external {
        Wager storage w = wagers[id];
        require(w.status == Status.Accepted, "Not accepted");
        require(msg.sender == w.creator || msg.sender == w.opponent, "Not participant");
        require(bytes(proofHash).length > 0, "Empty proof");
        
        w.claimant = msg.sender;
        w.proofHash = proofHash;
        w.proofTimestamp = block.timestamp;
        w.status = Status.ProofSubmitted;
        emit ProofSubmitted(id, msg.sender, proofHash);
    }
    
    function dispute(uint256 id, string calldata reason, string calldata evidenceHash) external {
        Wager storage w = wagers[id];
        require(w.status == Status.ProofSubmitted, "No proof submitted");
        require(!w.disputed, "Already disputed");
        require(msg.sender == w.creator || msg.sender == w.opponent, "Not participant");
        require(msg.sender != w.claimant, "Cannot dispute own claim");
        require(block.timestamp <= w.proofTimestamp + DISPUTE_WINDOW, "Dispute window closed");
        
        w.disputed = true;
        w.disputeReason = reason;
        w.disputeEvidenceHash = evidenceHash;
        w.status = Status.Disputed;
        emit WagerDisputed(id, msg.sender, reason);
    }
    
    function claimAfterTimeout(uint256 id) external {
        Wager storage w = wagers[id];
        require(w.status == Status.ProofSubmitted, "Wrong status");
        require(!w.disputed, "Is disputed");
        require(msg.sender == w.claimant, "Not claimant");
        require(block.timestamp > w.proofTimestamp + DISPUTE_WINDOW, "Window not closed");
        
        _payout(id, w.claimant);
    }
    
    function resolveDispute(uint256 id, address winner) external onlyAdmin {
        Wager storage w = wagers[id];
        require(w.status == Status.Disputed, "Not disputed");
        require(winner == w.creator || winner == w.opponent, "Invalid winner");
        
        _payout(id, winner);
    }
    
    function cancel(uint256 id) external {
        Wager storage w = wagers[id];
        require(w.status == Status.Open, "Not open");
        require(msg.sender == w.creator, "Not creator");
        
        w.status = Status.Cancelled;
        payable(w.creator).transfer(w.amount);
        emit WagerCancelled(id);
    }
    
    function _payout(uint256 id, address winner) internal {
        Wager storage w = wagers[id];
        uint256 totalPot = w.amount * 2;
        uint256 fee = (totalPot * FEE_BPS) / 10000;
        uint256 payout = totalPot - fee;
        
        w.status = Status.Resolved;
        payable(feeRecipient).transfer(fee);
        payable(winner).transfer(payout);
        emit WagerResolved(id, winner, payout);
    }
    
    function getWager(uint256 id) external view returns (
        address creator,
        address opponent,
        uint256 amount,
        Status status,
        string memory gameId,
        address claimant,
        string memory proofHash,
        uint256 proofTimestamp,
        bool disputed
    ) {
        Wager storage w = wagers[id];
        return (w.creator, w.opponent, w.amount, w.status, w.gameId, w.claimant, w.proofHash, w.proofTimestamp, w.disputed);
    }
}
