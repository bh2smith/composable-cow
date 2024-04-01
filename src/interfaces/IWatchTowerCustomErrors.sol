// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Watchtower Custom Error Interface
 * @author CoW Protocol Developers
 * @dev An interface that collects all custom error message for the watchtower.
 * Different error messages lead to different watchtower behaviors when creating
 * an order.
 * @dev The watchtower is a service that automatically posts orders to the CoW
 * Protocol orderbook at regular intervals.
 */
contract IWatchTowerCustomErrors {
    error PollTryAtEpoch(uint256 timestamp, string);
}