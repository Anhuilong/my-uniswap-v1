//SPDX-Lincese-Identifier: MIT
pragma solidity ^0.8.0;
/*
*    SPDX-Lincese-Identifier: MIT
*    pargma
*    import
*    contract
*    结构体 枚举
*    接口与抽象合约
*    常量和不可变量
*    状态变量
*    事件
*    错误
*    修饰器
*    构造函数
*    接收回退函数
*    外部函数
*    公开函数
*    内部函数
*    私有函数
*    视图函数纯函数
 */

import {IERC20} from "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFactory} from "../src/interface/IFactory.sol";
import {IExchange} from "./interface/IExchange.sol";
/**
 * @title 交易所合约
 * @author Ahl
 * @notice
 */

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    error Exchange__TokenAddressCannotBeZero();
    error Exchange__InsufficientTokenAmount();
    error Exchange__ReserveCannotBeZero();
    error Exchange__invalidReserves();
    error Exchange__ETHSoldCannotBeZero();
    error Exchange__TokenSoldCannotBeZero();
    error Exchange__NotEnoughTokensReceived();
    error Exchange__NotEnoughETHReceived();
    error Exchange__TransferFailed();
    error Exchange__invalidExchangeAddress();

    constructor(address _tokenAddress) ERC20("LPToken", "LP") {
        if (_tokenAddress == address(0)) {
            revert Exchange__TokenAddressCannotBeZero();
        }
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;
    }

    //增加流动性
    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
        //// 初始添加流动性，直接添加，不需要限制
        if (getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            //首次注入流动性时 ，发行的LP代币数量为存入的eth数量
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            // 后续新增流动性则需要按照当前的数量比例，等比增加
            // 保证价格添加流动性前后一致
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            if (_tokenAmount < tokenAmount) {
                revert Exchange__InsufficientTokenAmount();
            }
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            //增加流动性时，铸造的数量与存入的eth成正比
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    //返回交易所余额
    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    //返回兑换数量  一定数量的eth换多少token  一定数量的token换多少eth

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve)
        private
        pure
        returns (uint256)
    {
        if (inputReserve < 0 && outputReserve < 0) {
            revert Exchange__invalidReserves();
        }
        //加上交易手续费 1%的手续费 直接在存入的token或eth中扣除掉1%

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        //前面乘了99 应该是99% 所以这里乘100才可以保持不变
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }
    //计算ETH换取Token的数量

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if (_ethSold == 0) {
            revert Exchange__ETHSoldCannotBeZero();
        }
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }
    //计算Token换取ETH的数量

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        if (_tokenSold == 0) {
            revert Exchange__TokenSoldCannotBeZero();
        }
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    //使用ETH交换token
    function ethToTokenSwap(uint256 _minTokens /*希望用其以太币兑换的最小代币数量 */ ) public payable {
        //token储量
        uint256 tokenResvere = getReserve();
        //计算eth换取代币的数量  这里的eth数量在测试中直接用{value : eth}在函数中传入
        /**
         * 这里我们需要减去在函数中出入的eth，因为我们在函数中传入的eth也计入到余额里了，不删除的话就重复了，
         * 假如我们传入10个eth，那么余额address(this).balance就是1010了，我们需要用1000这个余额来计算获取token的数量
         */
        uint256 tokenBought = getAmount(msg.value, address(this).balance - msg.value, tokenResvere);
        //判断获取的token数量是否大于最小数量
        if (tokenBought < _minTokens) {
            revert Exchange__NotEnoughTokensReceived();
        }
        //转账token给msg.sender
        IERC20(tokenAddress).transfer(msg.sender, tokenBought);
    }
    //使用token交换eth

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        //ETH储量
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = getReserve();
        //计算token换取eth的数量
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, ethReserve);
        if (ethBought < _minEth) {
            revert Exchange__NotEnoughETHReceived();
        }
        //转账eth给调用者
        (bool success,) = msg.sender.call{value: ethBought}("");
        if (!success) {
            revert Exchange__TransferFailed();
        }
        //转账token给交易所合约
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
    }
    //流动性提取 取回自己的eth或者token

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        if (_amount < 0) {
            revert Exchange__invalidReserves();
        }
        //初始1000eth 2000token 1000LP 存入100eth 获得100LP  1100*100/1100 = 100
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();

        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        //销毁LP代币
        _burn(msg.sender, _amount);
        //转账
        (bool success,) = msg.sender.call{value: ethAmount}("");
        if (!success) {
            revert Exchange__TransferFailed();
        }
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    /**
     *
     * @param _tokenSold 要交换的代币数量
     * @param _minTokensBought 预期最少获得的目标代币数量
     * @param _tokenAddress 目标代币的合约地址
     * 这是一个用token换取token的方法 先将token换成ETH，并把代币转移到交易所
     */
    function tokenToTokenSwap(uint256 _tokenSold, uint256 _minTokensBought, address _tokenAddress) public {
        //检查目标交易所是否存在
        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);
        if (exchangeAddress == address(this) && exchangeAddress == address(0)) {
            revert Exchange__invalidExchangeAddress();
        }
        uint256 tokenReserve = getReserve();
        //token换成的eth数量
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        //将token转移到交易所
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);

        //使用其他交易所，将eth换成token
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(_minTokensBought, msg.sender);
    }
}
