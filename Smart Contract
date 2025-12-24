// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FreshChain {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only admin");
        _;
    }

    // ---- ROLES ----
    mapping(address => bool) public isProducer;
    mapping(address => bool) public isTransporter;
    mapping(address => bool) public isDistributor;
    mapping(address => bool) public isRetailer;

    modifier onlyProducer() {
        require(isProducer[msg.sender], "Only producer");
        _;
    }

    modifier onlyTransporter() {
        require(isTransporter[msg.sender], "Only transporter");
        _;
    }

    modifier onlyDistributor() {
        require(isDistributor[msg.sender], "Only distributor");
        _;
    }

    modifier onlyRetailer() {
        require(isRetailer[msg.sender], "Only retailer");
        _;
    }

    // ---- REGISTRATION ----
    function registerProducer(address a) external onlyOwner {
        isProducer[a] = true;
    }

    function registerTransporter(address a) external onlyOwner {
        isTransporter[a] = true;
    }

    function registerDistributor(address a) external onlyOwner {
        isDistributor[a] = true;
    }

    function registerRetailer(address a) external onlyOwner {
        isRetailer[a] = true;
    }

    // ---- DATA STRUCTURES ----
    struct SensorData {
        int temperature;
        int humidity;
        string location;
        uint timestamp;
        address transporter;
    }

    struct Ownership {
        address from;
        address to;
        uint timestamp;
    }

    struct Batch {
        uint batchId;
        string productName;
        uint quantity;
        address currentOwner;
        bool arrived;
        bool inspectionPassed;
        SensorData[] sensors;
        Ownership[] ownerships;
        bool exists;
    }

    mapping(uint => Batch) private batches;

    // ---- EVENTS ----
    event BatchCreated(uint batchId, string product, uint quantity);
    event SensorAdded(uint batchId, int temp, int hum, string location);
    event OwnershipTransferred(uint batchId, address from, address to);
    event Arrived(uint batchId, bool passed);

    // ---- FUNCTIONS ----
    function createBatch(
        uint batchId,
        string memory productName,
        uint quantity
    ) external onlyProducer {
        require(!batches[batchId].exists, "Batch exists");

        Batch storage b = batches[batchId];
        b.batchId = batchId;
        b.productName = productName;
        b.quantity = quantity;
        b.currentOwner = msg.sender;
        b.exists = true;

        b.ownerships.push(Ownership(address(0), msg.sender, block.timestamp));

        emit BatchCreated(batchId, productName, quantity);
    }

    function addSensorData(
        uint batchId,
        int temperature,
        int humidity,
        string memory location
    ) external onlyTransporter {
        require(temperature >= -10 && temperature <= 40, "Bad temp");
        require(humidity >= 0 && humidity <= 40, "Bad humidity");

        Batch storage b = batches[batchId];
        require(b.exists, "No batch");

        b.sensors.push(
            SensorData(
                temperature,
                humidity,
                location,
                block.timestamp,
                msg.sender
            )
        );

        emit SensorAdded(batchId, temperature, humidity, location);
    }

    function transferOwnership(uint batchId, address newOwner) external {
        Batch storage b = batches[batchId];
        require(b.exists, "No batch");
        require(msg.sender == b.currentOwner, "Not owner");

        address old = b.currentOwner;
        b.currentOwner = newOwner;

        b.ownerships.push(Ownership(old, newOwner, block.timestamp));
        emit OwnershipTransferred(batchId, old, newOwner);
    }

    function markAsArrived(uint batchId, bool passed) external onlyRetailer {
        Batch storage b = batches[batchId];
        require(b.exists, "No batch");

        b.arrived = true;
        b.inspectionPassed = passed;

        emit Arrived(batchId, passed);
    }

    // ---- CUSTOMER VIEW ----
    function getBatchHistory(uint batchId)
        external
        view
        returns (
            Batch memory
        )
    {
        require(batches[batchId].exists, "No batch");
        return batches[batchId];
    }
}
