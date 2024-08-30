// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import "../BaseConditionalOrder.sol";
import {ConditionalOrdersUtilsLib as Utils} from "./ConditionalOrdersUtilsLib.sol";
import {IWatchTowerCustomErrors} from "../interfaces/IWatchTowerCustomErrors.sol";

// --- error strings

/// @dev The buy token balance is above the (minimum) threshold.
string constant SUFFICIENT_BALANCE = "buyToken balance still above threshold";
string constant BALANCE_INSUFFICIENT = "balance insufficient";

/**
 * @title A smart contract that tops up the buyToken balance to a specified topUpValue whenever the balance falls below threshold.
 */
contract StableTopUp is BaseConditionalOrder {
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint32 validityBucketSeconds;
        uint256 lowBalanceThreshold;
        uint256 topUpAmount;
        uint256 pollFrequency;
        bytes32 appData;
    }

    /**
     * @inheritdoc IConditionalOrderGenerator
     * @dev If the `receivers`'s balance of `buyToken` is below the specified threshold, tops up the receiver to `topUpTo`
     * with from sellToken at the current market price (no limit!).
     */
    function getTradeableOrder(
        address owner,
        address,
        bytes32,
        bytes calldata staticInput,
        bytes calldata
    ) public view override returns (GPv2Order.Data memory order) {
        /// @dev Decode the payload into the trade below threshold parameters.
        StableTopUp.Data memory data = abi.decode(staticInput, (Data));
        uint256 nextPoll = block.timestamp + data.pollFrequency;

        uint256 receiverBalance = data.buyToken.balanceOf(data.receiver);
        // Don't allow the order to be placed if the balance is less than the threshold.
        if (receiverBalance >= data.lowBalanceThreshold) {
            revert IWatchTowerCustomErrors.PollTryAtEpoch(
                nextPoll,
                SUFFICIENT_BALANCE
            );
        }

        uint256 buyAmount = data.topUpAmount;
        // Sell Amount as 10% more than buyAmount
        // This is not super accurate, but does, kinda, cover most cases for truly stable coins.
        // Note that sDAI is an interest bearing token... so its value kinda "goes up" and eventually becomes
        uint256 sellAmount = (buyAmount * 110) / 100;

        uint256 funderBalance = data.sellToken.balanceOf(owner);
        if (!(funderBalance >= sellAmount)) {
            revert IWatchTowerCustomErrors.PollTryAtEpoch(
                nextPoll,
                BALANCE_INSUFFICIENT
            );
        }

        // ensures that orders queried shortly after one another result in the same hash (to avoid spamming the orderbook)
        order = GPv2Order.Data(
            data.sellToken,
            data.buyToken,
            data.receiver,
            sellAmount,
            buyAmount,
            Utils.validToBucket(data.validityBucketSeconds),
            data.appData,
            0,
            GPv2Order.KIND_SELL,
            false,
            GPv2Order.BALANCE_ERC20,
            GPv2Order.BALANCE_ERC20
        );
    }
}
