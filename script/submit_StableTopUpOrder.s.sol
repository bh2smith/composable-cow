// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";

import {IERC20, IERC20Metadata} from "@openzeppelin/interfaces/IERC20Metadata.sol";

// Safe contracts
import {Safe} from "safe/Safe.sol";
import {Enum} from "safe/common/Enum.sol";
import "safe/proxies/SafeProxyFactory.sol";
import {CompatibilityFallbackHandler} from "safe/handler/CompatibilityFallbackHandler.sol";
import {MultiSend} from "safe/libraries/MultiSend.sol";
import {SignMessageLib} from "safe/libraries/SignMessageLib.sol";
import "safe/handler/ExtensibleFallbackHandler.sol";
import {SafeLib} from "../test/libraries/SafeLib.t.sol";

// Composable CoW
import "../src/ComposableCoW.sol";
import {StableTopUp} from "../src/types/StableTopUp.sol";

/**
 * @title Submit a Stable Top Up Order to ComposableCoW
 * @author bh2smith <bh2smith@gmail.com>
 */
contract SubmitSingleOrder is Script {
    using SafeLib for Safe;

    event Log(string message, bytes32 salt, bytes value);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Safe safe = Safe(payable(vm.envAddress("SAFE")));
        StableTopUp topUpContract = StableTopUp(vm.envAddress("STABLE_TOP_UP"));
        ComposableCoW composableCow = ComposableCoW(vm.envAddress("COMPOSABLE_COW"));

        StableTopUp.Data memory topUpOrder = StableTopUp.Data({
            sellToken: IERC20(vm.envAddress("SDAI")),
            buyToken: IERC20(vm.envAddress("EURE")),
            receiver: vm.envAddress("GNOSIS_PAY_SAFE"),
            validityBucketSeconds: 30 minutes,
            // 100 EURe
            lowBalanceThreshold: 100_000_000_000_000_000_000,
            // 200 EURe
            topUpAmount: 200_000_000_000_000_000_000,
            pollFrequency: 12 hours,
            appData: vm.envBytes32("APP_DATA")
        });
        vm.startBroadcast(deployerPrivateKey);

        bytes memory input = abi.encode(topUpOrder);
        bytes32 salt = keccak256(abi.encodePacked("StableTopUp"));
        emit Log("staticInput", salt, input);

        revert("Send the emitted log data in Safe Tx Builder!");
        // call to ComposableCoW to submit a single order
        safe.executeSingleOwner(
            address(composableCow),
            0,
            abi.encodeCall(
                composableCow.create,
                (
                    IConditionalOrder.ConditionalOrderParams({
                        handler: IConditionalOrder(topUpContract),
                        salt: salt,
                        staticInput: input
                    }),
                    true
                )
            ),
            Enum.Operation.Call,
            vm.addr(deployerPrivateKey)
        );

        vm.stopBroadcast();
    }
}
