// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FreshChain {
    address public owner;

    constructor() {
        owner = msg.sender;

        // OPTIONAL: make the deployer a producer so demo seeding is possible
        isProducer[msg.sender] = true;

        // OPTIONAL demo batches (turn off if you don't want)
        bool SEED_DEMO = true;
        if (SEED_DEMO) {
            _createBatchInternal(1, "Demo Apples", 100, msg.sender);
            _createBatchInternal(2, "Demo Milk", 50, msg.sender);
            _createBatchInternal(3, "Demo Carrots", 200, msg.sender);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

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

    /* ---------- ROLES ---------- */
    mapping(address => bool) public isProducer;
    mapping(address => bool) public isTransporter;
    mapping(address => bool) public isDistributor;
    mapping(address => bool) public isRetailer;

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

    /* ---------- DATA STRUCTURES ---------- */

    struct SensorData {
        int256 temperature;
        int256 humidity;
        string location;
        uint256 timestamp;
        address transporter;
    }

    struct Ownership {
        address from;
        address to;
        uint256 timestamp;
    }

    struct Batch {
        uint256 batchId;
        string productName;
        uint256 quantity;
        address producer;
        address currentOwner;
        address distributor;
        address retailer;
        bool arrived;
        bool inspectionPassed;
        bool exists;
        SensorData[] sensors;
        Ownership[] ownerships;
    }

    mapping(uint256 => Batch) public batches;

    // ✅ NEW: store all batch IDs so we can list them
    uint256[] private batchIds;

    function listBatches() external view returns (uint256[] memory) {
        return batchIds;
    }

    /* ---------- PRODUCER ---------- */

    function createBatch(
        uint256 batchId,
        string calldata productName,
        uint256 quantity
    ) external onlyProducer {
        require(!batches[batchId].exists, "Batch exists");
        _createBatchInternal(batchId, productName, quantity, msg.sender);
    }

    function _createBatchInternal(
        uint256 batchId,
        string memory productName,
        uint256 quantity,
        address producerAddr
    ) internal {
        Batch storage b = batches[batchId];
        b.batchId = batchId;
        b.productName = productName;
        b.quantity = quantity;
        b.producer = producerAddr;
        b.currentOwner = producerAddr;
        b.exists = true;

        batchIds.push(batchId);

        b.ownerships.push(Ownership(address(0), producerAddr, block.timestamp));
    }

    /* ---------- TRANSPORTER ---------- */

    function addSensorData(
        uint256 batchId,
        int256 temperature,
        int256 humidity,
        string calldata location
    ) external onlyTransporter {
        require(batches[batchId].exists, "No batch");

        batches[batchId].sensors.push(
            SensorData(
                temperature,
                humidity,
                location,
                block.timestamp,
                msg.sender
            )
        );
    }

    /* ---------- DISTRIBUTOR ---------- */

    function transferOwnership(
        uint256 batchId,
        address newOwner
    ) external onlyDistributor {
        require(batches[batchId].exists, "No batch");

        Batch storage b = batches[batchId];
        address oldOwner = b.currentOwner;
        b.currentOwner = newOwner;
        b.distributor = msg.sender;

        b.ownerships.push(Ownership(oldOwner, newOwner, block.timestamp));
    }

    /* ---------- RETAILER ---------- */

    function markAsArrived(
        uint256 batchId,
        bool passed
    ) external onlyRetailer {
        require(batches[batchId].exists, "No batch");

        Batch storage b = batches[batchId];
        b.arrived = true;
        b.inspectionPassed = passed;
        b.retailer = msg.sender;
    }

    /* ---------- VIEW (SCAN) ---------- */

    function getBatchHistory(uint256 batchId)
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            address,
            address,
            address,
            address,
            bool,
            bool,
            SensorData[] memory,
            Ownership[] memory
        )
    {
        require(batches[batchId].exists, "No batch");

        Batch storage b = batches[batchId];

        return (
            b.batchId,
            b.productName,
            b.quantity,
            b.producer,
            b.distributor,
            b.retailer,
            b.currentOwner,
            b.arrived,
            b.inspectionPassed,
            b.sensors,
            b.ownerships
        );
    }
}
