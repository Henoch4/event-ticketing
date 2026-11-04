// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract EventTicketing is ReentrancyGuard, Ownable {
    struct Event {
        address organizer;
        string title;
        string description;
        uint256 totalTickets;
        uint256 soldTickets;
        uint256 pricePerTicket;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool completed;
    }
    Event[] public events;
    mapping(uint256 => mapping(address => uint256)) public tickets;
    mapping(address => uint256[]) public userEvents;
    uint256 public eventCount;
    uint256 public totalRevenue;
    mapping(uint256 => uint256) public eventRevenue;

    event EventCreated(uint256 indexed eid, address indexed organizer, string title, uint256 price, uint256 supply);
    event TicketBought(uint256 indexed eid, address indexed buyer, uint256 qty, uint256 paid);
    event EventCompleted(uint256 indexed eid, address indexed organizer);

    function createEvent(string memory title, string memory description, uint256 totalTickets, uint256 pricePerTicket, uint256 startTime, uint256 endTime)
        external onlyOwner nonReentrant returns (uint256) {
        require(totalTickets > 0, "Zero supply");
        require(pricePerTicket > 0, "Zero price");
        require(startTime < endTime, "Invalid time");
        require(endTime > block.timestamp, "Event already ended");
        Event storage e = events.push();
        e.organizer = msg.sender;
        e.title = title;
        e.description = description;
        e.totalTickets = totalTickets;
        e.soldTickets = 0;
        e.pricePerTicket = pricePerTicket;
        e.startTime = startTime;
        e.endTime = endTime;
        e.active = true;
        e.completed = false;
        uint256 eid = events.length - 1;
        eventCount = eid + 1;
        userEvents[msg.sender].push(eid);
        emit EventCreated(eid, msg.sender, title, pricePerTicket, totalTickets);
        return eid;
    }

    function buyTicket(uint256 eid, uint256 qty) external payable nonReentrant {
        Event storage e = events[eid];
        require(e.active, "Event inactive");
        require(!e.completed, "Event completed");
        require(qty > 0, "Zero tickets");
        require(block.timestamp < e.endTime, "Event ended");
        require(e.soldTickets + qty <= e.totalTickets, "Not enough tickets");
        uint256 cost = e.pricePerTicket * qty;
        require(msg.value == cost, "Incorrect payment");
        e.soldTickets += qty;
        e.active = e.soldTickets < e.totalTickets;
        tickets[eid][msg.sender] += qty;
        totalRevenue += cost;
        eventRevenue[eid] += cost;
        emit TicketBought(eid, msg.sender, qty, cost);
    }

    function completeEvent(uint256 eid) external onlyOwner {
        Event storage e = events[eid];
        require(!e.completed, "Already completed");
        require(block.timestamp >= e.endTime, "Event not ended");
        e.completed = true;
        e.active = false;
        emit EventCompleted(eid, e.organizer);
    }

    // FIX: buyTicket collected ETH into totalRevenue with no exit path — one-way lockbox.
    // Organizer can now withdraw their event's revenue via pull-payment.
    function withdrawRevenue(uint256 eid) external nonReentrant {
        Event storage e = events[eid];
        require(msg.sender == e.organizer, "Only organizer");
        uint256 revenue = eventRevenue[eid];
        require(revenue > 0, "No revenue to withdraw");
        eventRevenue[eid] = 0;
        (bool ok,) = payable(e.organizer).call{value: revenue}("");
        require(ok, "ETH transfer failed");
    }

    function getEvent(uint256 eid) external view returns (address organizer, string memory title, string memory description, uint256 totalTickets, uint256 soldTickets, uint256 price, uint256 startTime, uint256 endTime, bool active, bool completed) {
        Event storage e = events[eid];
        return (e.organizer, e.title, e.description, e.totalTickets, e.soldTickets, e.pricePerTicket, e.startTime, e.endTime, e.active, e.completed);
    }
    function getTicketBalance(uint256 eid, address user) external view returns (uint256) { return tickets[eid][user]; }
}
