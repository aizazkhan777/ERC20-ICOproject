//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ICO {
    IERC20 public MAKToken;
    address public admin;
    address payable public deposit;

    uint public saleStart;
    uint public saleEnd;

    uint public hardCap;
    uint public totalInvested;
    uint public tokenPrice;

    uint public minInvestment;
    uint public maxInvestment;

    constructor(address _tokenAddress) {
        MAKToken = IERC20(0xFAB7a3E98C551d11dBcb82eE3aA53c3d3C6d2c8E);
        admin = msg.sender;
        deposit = payable(msg.sender);

        saleStart = block.timestamp; // Sale starts at deployment
        saleEnd = saleStart + 604800; // 1 week duration

        hardCap = 0.02 ether; 
        totalInvested = 0;

        minInvestment = 0.001 ether;
        maxInvestment = 0.01 ether;

        tokenPrice = 0.001 ether; // Adjust as per your tokenomics
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    modifier saleActive() {
        require(block.timestamp >= saleStart && block.timestamp <= saleEnd, "Sale not active");
        require(totalInvested < hardCap, "Hard cap reached");
        _;
    }

    function setDepositAddress(address _deposit) public onlyAdmin {
        deposit = payable(_deposit);
    }

    function buyTokens() public payable saleActive {
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Investment out of range");
        uint tokensToBuy = msg.value / tokenPrice;
        require(MAKToken.balanceOf(address(this)) >= tokensToBuy, "Not enough tokens in the contract");

        totalInvested += msg.value;
        MAKToken.transfer(msg.sender, tokensToBuy);
    }

    function withdrawFunds() public onlyAdmin {
        require(block.timestamp > saleEnd, "Sale not ended");
        deposit.transfer(address(this).balance);
    }

    function endSale() public onlyAdmin {
        require(block.timestamp > saleEnd || totalInvested >= hardCap, "Sale not ended");
        uint remainingTokens = MAKToken.balanceOf(address(this));
        if (remainingTokens > 0) {
            MAKToken.transfer(admin, remainingTokens);
        }
        deposit.transfer(address(this).balance);
    }
    //0x030eccAA52a3713AF8592c5acB52055297F0559b contract address
}
