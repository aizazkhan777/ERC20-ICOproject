// SPDX-License-Identifier: GPL-3.0
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
    
    struct Subscription {
        address addr;
        bool eligibleForTokens;
    }

    Subscription[4] public subscriptionList;
    uint public subscriberCount = 0;
    uint public eligibleSubscriberCount = 0;

    constructor(address _tokenAddress) {
        MAKToken = IERC20(_tokenAddress);
        admin = msg.sender;
        deposit = payable(msg.sender);

        saleStart = block.timestamp;
        saleEnd = saleStart + 604800;

        hardCap = 0.02 ether;
        totalInvested = 0;

        minInvestment = 0.001 ether;
        maxInvestment = 0.01 ether;

        tokenPrice = 0.001 ether;
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

    function addSubscriber() public {
        require(subscriberCount < 4, "Subscription list is full");
        subscriptionList[subscriberCount] = Subscription(msg.sender, eligibleSubscriberCount < 2);
        subscriberCount++;
        if (eligibleSubscriberCount < 2) {
            eligibleSubscriberCount++;
        }
    }

    function calculateTokensToBuy() internal pure returns (uint256) {
        return 1; // Each eligible subscriber receives 1 token
    }

    function distributeTokens() public onlyAdmin {
        require(block.timestamp > saleEnd, "Sale not ended");
        require(eligibleSubscriberCount >= 2, "At least 2 eligible subscribers required");

        address[] memory selectedSubscribers = new address[](2);
        uint[] memory selectedIndices = new uint[](2);

        for (uint i = 0; i < 2; i++) {
            uint randomIndex;
            do {
                randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % subscriberCount;
            } while (!subscriptionList[randomIndex].eligibleForTokens);

            selectedSubscribers[i] = subscriptionList[randomIndex].addr;
            selectedIndices[i] = randomIndex;

            subscriptionList[randomIndex].eligibleForTokens = false; // Mark subscriber as not eligible for future distributions
        }

        for (uint i = 0; i < 2; i++) {
            MAKToken.transfer(selectedSubscribers[i], calculateTokensToBuy()); // Transfer tokens to selected subscribers
        }

        for (uint i = 0; i < subscriberCount; i++) {
            if (i != selectedIndices[0] && i != selectedIndices[1]) {
                payable(subscriptionList[i].addr).transfer(minInvestment); // Refund non-selected subscribers
            }
        }
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

    function depositTokens(uint256 _amount) public {
        require(block.timestamp < saleStart, "Sale has started");
        require(MAKToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
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
}
