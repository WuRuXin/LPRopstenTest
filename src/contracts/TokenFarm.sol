pragma solidity ^0.5.0;

import "./DappToken.sol";
import "./IERC20.sol";

contract TokenFarm {
    using SafeMath for uint;

    string public name = "Dapp Token Farm";
    address public owner;
    DappToken public dappToken;
    IERC20 public daiToken;
    bool private flag;

    address[] public stakers;
    mapping(address => uint) public stakingBalance; // 质押余额
    mapping(address => uint) public issueBalance;   // 奖励余额
    mapping(address => bool) public hasStaked;      // 是否质押
    mapping(address => bool) public isStaking;      // 是否存有质押
    mapping(address => IERC20) public tokenMap;    // 存储token

    constructor(DappToken _dappToken) public {
        dappToken = _dappToken;
        owner = msg.sender;
    }

    // 防止重入
    modifier lock() {
        require(!flag, "flag is true");
        flag = true;
        _;
        flag = false;
    }

    // 质押LP，参数：token地址，数量
    function stakeTokens(address _daiToken, uint _amount) public {
        // 实例化
        daiToken = IERC20(_daiToken);
        tokenMap[msg.sender] = daiToken;
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        // msg.sender账户向TokenFarm地址转移_amount个daiToken
        daiToken.transferFrom(msg.sender, address(this), _amount);
        // 存储质押信息
        stakingBalance[msg.sender] = stakingBalance[msg.sender].add(_amount);
        issueBalance[msg.sender] = issueBalance[msg.sender].add(_amount);

        // 判断是否已经转账过
        if(!hasStaked[msg.sender]) {
            // 存储数组
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // 取出全部质押
    function unstakeTokens() public lock {
        // 获取质押余额
        uint balance = stakingBalance[msg.sender];
        
        // 获取实例化token
        daiToken = tokenMap[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // 合约地址向调用者转账
        daiToken.transfer(msg.sender, balance);

        // 清空记录
        stakingBalance[msg.sender] = 0;

        // 转账完成
        isStaking[msg.sender] = false;
    }

    // 奖励dappToken
    function issueTokens() public lock{
        uint balance = issueBalance[msg.sender];
        if(balance > 0) {
            // 将奖励余额归0
            issueBalance[msg.sender] = 0;
            dappToken.transfer(msg.sender, balance);
        }
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
