//SPDX-Lincese-Identifier: MIT
pragma solidity ^0.8.0;

import {Exchange} from "../src/Exchange.sol";

contract Factory {
    mapping(address => address) public tokenToExchange;

    error Factory__TokenAddressCannotBeZero();
    error Factory__TokenAlreadyExists();
    //createExchange允许通过简单地获取令牌地址来创建和部署交换的功能：
    //一个令牌对应一个交易所

    function createExchange(address _tokenAddress) public returns (address) {
        //不能是0地址 不能是添加到列表中的
        if (_tokenAddress == address(0)) {
            revert Factory__TokenAddressCannotBeZero();
        }
        if (tokenToExchange[_tokenAddress] != address(0)) {
            revert Factory__TokenAlreadyExists();
        }

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);
        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}
