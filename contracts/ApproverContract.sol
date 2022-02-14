// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

contract ApproverContract {
    enum Status {
        New,
        Ready,
        InTransfer,
        Approved
    }
    struct Order {
        int256 id;
        address client;
        uint256 price;
        Status status;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner.");

        _;
    }

    event NewOrderEvent(int256 orderId);
    event OrderReadyEvent(int256 orderId);
    event OrderInTransitEvent(int256 orderId, address courier);
    event OrderApprovedEvent(address client, uint256 fee, uint256 price);

    address payable owner;
    mapping(int256 => Order) orders;
    mapping(int256 => address payable) transfers;

    int256 private orderId;

    constructor() {
        owner = payable(msg.sender);
    }

    function placeOrder(uint256 _price) public returns (Status) {
        orderId++;
        Order memory order = Order(orderId, msg.sender, _price, Status.New);
        orders[orderId] = order;

        emit NewOrderEvent(orderId);

        return order.status;
    }

    function readyOrder(int256 _orderId) public onlyOwner returns (Status) {
        orders[_orderId].status = Status.Ready;
        emit OrderReadyEvent(orderId);

        return orders[_orderId].status;
    }

    function takeOrder(int256 _orderId) public returns (Status) {
        Order memory order = orders[_orderId];
        order.status = Status.InTransfer;

        transfers[_orderId] = payable(msg.sender);

        emit OrderInTransitEvent(_orderId, msg.sender);

        return order.status;
    }

    function approveOrder(int256 _orderId) public returns (Status) {
        Order memory order = orders[_orderId];
        address payable courier = transfers[_orderId];

        order.status = Status.Approved;

        uint256 fee = (order.price * 10) / 100;
        order.price -= fee;

        courier.transfer(fee);
        owner.transfer(order.price);

        emit OrderApprovedEvent(msg.sender, fee, order.price);

        return order.status;
    }

    receive() external payable {}
}
