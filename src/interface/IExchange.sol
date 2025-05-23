//SPDX-Lincese-Identifier: MIT
pragma solidity ^0.8.0;

import {Factory} from "../../src/Factory.sol";

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}
