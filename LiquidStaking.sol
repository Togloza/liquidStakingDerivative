// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/Staking20Base.sol";

contract LiquidStaking is Staking20Base {
    uint256 totalPool;
    uint256 LSTGiven;
    // address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // address LST = 0x9793Bf784e5Bd604E4CDD0E367dB8Eab2B41f2A0
    // address FakeToken = 0x21165E010f74d9a36F154ca5bd889D5c173Cfc6F
    constructor(
        address _stakingToken,
        address _rewardToken,
        address _nativeTokenWrapper
    )
        Staking20Base(
            _stakingToken,
            _rewardToken,
            _nativeTokenWrapper
        )
    {}



    function _stake(uint256 _amount) internal virtual override {
        require(_amount != 0, "Staking 0 tokens");

        address _stakingToken;
        if (stakingToken == CurrencyTransferLib.NATIVE_TOKEN) {
            _stakingToken = nativeTokenWrapper;
        } else {
            require(msg.value == 0, "Value not 0");
            _stakingToken = stakingToken;
        }

        uint256 balanceBefore = IERC20(_stakingToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrencyWithWrapper(
            stakingToken,
            _stakeMsgSender(),
            address(this),
            _amount,
            nativeTokenWrapper
        );

        uint256 actualAmount = IERC20(_stakingToken).balanceOf(address(this)) - balanceBefore;

        uint256 quote = getStakeQuote(actualAmount);
        CurrencyTransferLib.transferCurrency(rewardToken, address(this), _stakeMsgSender(), quote);
        
        totalPool += actualAmount;
        LSTGiven += quote;

        emit TokensStaked(_stakeMsgSender(), actualAmount);
    }

    function _unstake(uint256 _amount) internal virtual override{
        require(_amount != 0, "Unstaking 0 tokens");
        require(IERC20(rewardToken).balanceOf(msg.sender) >= _amount, "Unstaking more than owned");

        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));
        CurrencyTransferLib.transferCurrency(
            rewardToken,
            _stakeMsgSender(),
            address(this),
            _amount
        );
        uint256 actualAmount = IERC20(rewardToken).balanceOf(address(this)) - balanceBefore;

        uint256 quote = getUnstakeQuote(actualAmount);
        CurrencyTransferLib.transferCurrencyWithWrapper(
            stakingToken,
            address(this),
            _stakeMsgSender(),
            quote,
            nativeTokenWrapper
        );

        LSTGiven -= actualAmount;
        totalPool -= quote; 

        emit TokensWithdrawn(_stakeMsgSender(), _amount);
    }


    function getStakeQuote(uint _amount) public view returns(uint256){
        require(_amount > 0, "Amount must be greater than zero");
        
        //uint baseAmount = _amount / decimalMultiplier; // Convert to base unit
        uint256 outputTokens = LSTGiven * (((totalPool + _amount) / totalPool) - 1); //outputTokens = LSTGiven * (((totalPool + baseAmount) / totalPool) - 1)

        uint256 equivalentLSTs = outputTokens; //* decimalMultiplier; 
        return equivalentLSTs;
    }

    
    function getUnstakeQuote(uint256 _amount) public view returns(uint256){
        require(_amount > 0, "Amount must be greater than zero");
        
        //uint baseAmount = _amount / decimalMultiplier; // Convert to base unit
        uint owedRewards = totalPool / LSTGiven;
        uint outputTokens = _amount * owedRewards; //baseAmount * owedRewards

        uint256 equivalentCantoTokens = outputTokens;  //outputTokens * decimalMultiplier
        return equivalentCantoTokens;
    }

    function rewardTokenAmount() public view returns(uint _amount){
        return IERC20(rewardToken).balanceOf(address(this));
    }

    function senderRewardTokenAmount() public view returns(uint _amount){
        return IERC20(rewardToken).balanceOf(msg.sender);
    }
    function stakeTokenAmount() public view returns(uint _amount){
        return IERC20(stakingToken).balanceOf(address(this));
    }

    function senderStakeTokenAmount() public view returns(uint _amount){
        return IERC20(stakingToken).balanceOf(msg.sender);
    }

    
    function _queryTotalPool() public view returns(uint256){
        return totalPool;
    }

    function _queryGivenRewardToken() public view returns (uint256) {
        return LSTGiven;
    }

    function checkRewardTokenApproval() public view returns (uint256) {
        return IERC20(rewardToken).allowance(msg.sender, address(this));
    }

    function checkStakingTokenApproval() public view returns (uint256) {
        return IERC20(stakingToken).allowance(msg.sender, address(this));
    }   
}