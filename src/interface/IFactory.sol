//SPDX-Lincese-Identifier: MIT
pragma solidity ^0.8.0;

import {Factory} from "../../src/Factory.sol";

interface IFactory {
    function getExchange(address _tokenAddress) external returns (address);
}
