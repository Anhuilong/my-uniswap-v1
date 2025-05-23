//SPDX-Lincese-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";
import {DeployExchange} from "../script/DeployExchange.s.sol";
import {IERC20} from "../openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ExchangeTest is Test {
    receive() external payable {}

    Exchange exchange;
    Token token;
    DeployExchange deployer;
    address user = makeAddr("user");
    uint256 constant TOKEN_AMOUNT = 1000000e18;
    uint256 constant LIQUIDITY_TOKEN_AMOUNT = 2000e18;
    uint256 constant LIQUIDITY_ETH_AMOUNT = 1000e18;
    mapping(address => uint256) public tokenBalances;

    modifier AddLiquidity() {
        token.approve(address(exchange), LIQUIDITY_TOKEN_AMOUNT);
        exchange.addLiquidity{value: LIQUIDITY_ETH_AMOUNT}(LIQUIDITY_TOKEN_AMOUNT);
        _;
    }

    function setUp() public {
        token = new Token("AhlToken", "AHL", TOKEN_AMOUNT);
        exchange = new Exchange(address(token));
    }
    //测试第一次注入流动性铸造的LP代币

    function testOneAddLiquidity() public AddLiquidity {
        assertEq(exchange.totalSupply(), 1000e18);
    }

    //测试第二次注入流动性铸造的代币

    function testTwoAddLiquidity() public AddLiquidity {
        token.approve(address(exchange), 200e18);
        exchange.addLiquidity{value: 100e18}(200e18);
        assertEq(exchange.totalSupply(), 1100e18);
    }

    //测试返回token余额
    function testgetReserve() public AddLiquidity {
        assertEq(exchange.getReserve(), 2000e18);
    }

    //测试token兑换eth数量
    function testgetethAmount() public AddLiquidity {
        uint256 ethAmount = exchange.getEthAmount(100e18);
        assertEq(ethAmount, 47165316817532158170);
    }

    //测试ETH兑换token数量
    function testgetTokenAmount() public AddLiquidity {
        uint256 tokenAmount = exchange.getTokenAmount(100e18);
        assertEq(tokenAmount, 180163785259326660600);
    }

    //测试ETH交换token
    function testethToTokenSwap() public AddLiquidity {
        exchange.ethToTokenSwap{value: 100e18}(170e18);
        assertEq(exchange.getReserve(), 1819836214740673339400);
    }

    //测试token交换ETH
    function testtokenToEthSwap() public AddLiquidity {
        token.approve(address(exchange), 100e18);
        exchange.tokenToEthSwap(100e18, 45e18);
    }

    //测试拿回流动性
    function testRemoveLiquidity() public AddLiquidity {
        token.approve(address(exchange), 400e18);
        exchange.addLiquidity{value: 200e18}(400e18);
        exchange.removeLiquidity(200e18);
    }
}
