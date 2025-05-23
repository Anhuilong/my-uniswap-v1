//SPDX-Lincese-Identifier:  uint256 constant TOKEN_AMOUNT = 1000000e18; MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";



contract DeployExchange is Script{
    uint256 constant TOKEN_AMOUNT = 1000000e18; 
    function run() external returns(Exchange, Token){
        vm.startBroadcast();
        Token token = new Token("AhlToken","AHL", TOKEN_AMOUNT);
        Exchange exchange = new Exchange(address(token));
        vm.stopBroadcast();
        return (exchange, token);
}
}