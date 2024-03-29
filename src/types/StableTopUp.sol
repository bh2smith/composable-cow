// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

import "../BaseConditionalOrder.sol";
import {ConditionalOrdersUtilsLib as Utils} from "./ConditionalOrdersUtilsLib.sol";

// --- error strings

/// @dev The buy token balance is above the (minimum) threshold.
string constant SUFFICIENT_BALANCE = "buyToken balance above threshold";

/**
 * @title A smart contract that trades whenever its balance of a certain token exceeds a target threshold
 */
contract StableTopUp is BaseConditionalOrder {
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint32 validityBucketSeconds;
        uint256 threshold;
        uint256 topUpTo;
        bytes32 appData;
    }

    /**
     * @inheritdoc IConditionalOrderGenerator
     * @dev If the `receivers`'s balance of `buyToken` is below the specified threshold, tops up the receiver to `topUpTo`
     * with from sellToken at the current market price (no limit!).
     */
    function getTradeableOrder(
        address,
        address,
        bytes32,
        bytes calldata staticInput,
        bytes calldata
    ) public view override returns (GPv2Order.Data memory order) {
        /// @dev Decode the payload into the trade below threshold parameters.
        StableTopUp.Data memory data = abi.decode(staticInput, (Data));

        uint256 balance = data.buyToken.balanceOf(data.receiver);
        // Don't allow the order to be placed if the balance is less than the threshold.
        if (balance >= data.threshold) {
            revert IConditionalOrder.OrderNotValid(SUFFICIENT_BALANCE);
        }
        uint256 buyAmount = data.topUpTo - balance;
        // ensures that orders queried shortly after one another result in the same hash (to avoid spamming the orderbook)
        order = GPv2Order.Data(
            data.sellToken,
            data.buyToken,
            data.receiver,
            // Sell Amount as 10% more than buyAmount
            // Assuming Stable Coins (Balance LP tokens are "stable").
            (buyAmount * 110) / 100,
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
