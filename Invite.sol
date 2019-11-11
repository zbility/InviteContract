pragma solidity ^0.4.21;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
* 规则：
* 1. 奖励分配规则；
* 2. 规则 LEVEL 定义奖励层级；
* 3. decimal & rule 定义权重比例；
#################################################################
 例如：
    reward = 100
    decimal = 100
    rule = [60,40]
 解析：
   1级获得 60
   2级获得  40
   leader  0(未分配的量)
#################################################################
*/
contract InviteInterface {

    function leader() external view returns (address);

    function truster() external view returns (address);

    function decimal() external view returns (uint256);

    function rule() external view returns (uint256[]);

    function checkRule() external view returns (bool);

    function getReward(address account) external view returns (uint256);

    function reward(uint256 amount, address[] inviters) external returns (bool);
}

contract Invite is InviteInterface {

    uint256 constant private LEVEL = 2;
    address private _leader;
    address private _truster;
    uint256[] private _rule;
    uint256 private _decimal;
    mapping(address => uint256) private _rewards;

    event rewardMember(address receiver, uint256 amount);
    event rewardLeader(address receiver, uint256 amount);

    /**
     * #leader: 承销节点自己的地址
     * #truster: 官方调用合约地址
     * #decimal: 将奖励精确划分份额
     * #rule: 每层权重规则
     */
    function Invite(address leader, address truster, uint256 decimal, uint256[] rule) public {
        _truster = truster;
        _leader = leader;
        _decimal = decimal;
        _rule = rule;
        require(_checkRule());
    }

    function leader() external view returns (address) {
        return _leader;
    }

    function truster() external view returns (address) {
        return _truster;
    }

    function rule() external view returns (uint256[]) {
        return _rule;
    }

    function decimal() external view returns (uint256) {
        return _decimal;
    }

    function getReward(address account) external view returns (uint256) {
        return _rewards[account];
    }

    function reward(uint256 amount, address[] inviters) external returns (bool){
        require(msg.sender == _truster);
        require(amount > 0);

        uint256 balance = amount;
        for (uint256 i = 0; i < LEVEL; i++) {
            if (i >= _rule.length || i >= inviters.length || balance == 0) {
                break;
            }
            address to = inviters[i];
            if (to == address(0x0)) {
                break;
            }
            if (_rule[i] > 0) {
                uint256 _amount = SafeMath.div(SafeMath.mul(amount, _rule[i]), _decimal);
                if (balance < _amount) {
                    _amount = balance;
                }
                _rewards[to] = SafeMath.add(_rewards[to], _amount);
                emit rewardMember(to, _amount);
                balance = SafeMath.sub(balance, _amount);
            }
        }
        if (balance > 0) {
            _rewards[_leader] = SafeMath.add(_rewards[_leader], balance);
            emit rewardLeader(_leader, balance);
        }
        return true;
    }

    function checkRule() external view returns (bool) {
        return _checkRule();
    }

    function _checkRule() internal view returns (bool) {
        if (_decimal == 0) {
            return false;
        }
        if (_rule.length > LEVEL) {
            return false;
        }
        uint256 sum = 0;
        for (uint256 i = 0; i < _rule.length; i++) {
            sum = SafeMath.add(sum, _rule[i]);
        }
        if (sum <= 0 || sum > _decimal) {
            return false;
        }
        return true;
    }
}
