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

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Safe safe = Safe(payable(vm.envAddress("SAFE")));
        StableTopUp topUpContract = StableTopUp(vm.envAddress("STABLE_TOP_UP"));
        ComposableCoW composableCow = ComposableCoW(vm.envAddress("COMPOSABLE_COW"));

        StableTopUp.Data memory topUpOrder = StableTopUp.Data({
            sellToken: IERC20(address(1)),
            buyToken: IERC20(address(2)),
            receiver: address(0),
            validityBucketSeconds: 10,
            topUpTo: 100_000_000_000_000_000_000,
            appData: keccak256("forge.scripts.stable_top_up")
        });

        vm.startBroadcast(deployerPrivateKey);

        // call to ComposableCoW to submit a single order
        safe.executeSingleOwner(
            address(composableCow),
            0,
            abi.encodeCall(
                composableCow.create,
                (
                    IConditionalOrder.ConditionalOrderParams({
                    handler: IConditionalOrder(topUpContract),
                    salt: keccak256(abi.encodePacked("StableTopUp")),
                    staticInput: abi.encode(topUpOrder)
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
