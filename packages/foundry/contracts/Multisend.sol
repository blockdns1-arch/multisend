//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 } from "../lib/forge-std/src/console2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisend {
    // Event declarations
    event SuccessfulETHTransfer(address indexed _sender, address payable[] _receivers, uint256[] _amounts);
    event SuccessfulTokenTransfer(address indexed _sender, address[] indexed _receivers, uint256[] _amounts, address _token);

    /// @notice sends ETH to multiple recipients.
    /// @dev recipients and amounts must be equal length, and msg.value must exactly equal the sum of amounts.
    function sendETH(address payable[] memory recipients, uint256[] memory amounts) external payable {
        require(recipients.length == amounts.length, "multisend: recipient/amount length mismatch");

        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(msg.value == total, "multisend: msg.value does not equal sum of amounts");

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{ value: amounts[i] }("");
            require(sent, "multisend: ETH transfer failed");
        }

        emit SuccessfulETHTransfer(msg.sender, recipients, amounts);
    }

    /// @notice sends ERC20 tokens to multiple recipients.
    /// @dev recipients and amounts must be equal length; caller must have approved this contract for the total.
    function sendTokens(address[] memory recipients, uint256[] memory amounts, address token) external {
        require(recipients.length == amounts.length, "multisend: recipient/amount length mismatch");

        IERC20 erc20 = IERC20(token);
        for (uint256 i = 0; i < recipients.length; i++) {
            require(erc20.transferFrom(msg.sender, recipients[i], amounts[i]), "multisend: token transfer failed");
        }

        emit SuccessfulTokenTransfer(msg.sender, recipients, amounts, token);
    }
}