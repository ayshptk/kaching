//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
}

contract Kaching {
    uint256 private last;
    uint256 private lastSubscription;
    address private owner;
    address public immutable USDC_ADDRESS;

    struct Option {
        string name;
        uint256 price;
        bool active;
        address owner;
        uint256 interval;
        address token;
    }

    struct Subscription {
        uint256 id;
        bool active;
        address owner;
        uint256 lastPayment;
    }

    event SubscriptionCreated(uint256 indexed subscriptionId, uint256 interval);
    event SubscriptionDestroyed(uint256 indexed subscriptionId);
    event SubscriptionPaid(
        uint256 indexed subscriptionId,
        uint256 amount,
        address sender
    );

    mapping(uint256 => Option) public options;
    mapping(uint256 => Subscription) public subscriptions;

    constructor(address _usdcAddress) {
        last = 0;
        owner = msg.sender;
        USDC_ADDRESS = _usdcAddress;
    }

    function createUsdcSubscription(
        string memory _name,
        uint256 _price,
        uint256 _interval
    ) public returns (uint256) {
        return
            _createSubscription(
                _name,
                _price,
                msg.sender,
                _interval,
                USDC_ADDRESS
            );
    }

    function createUsdcSubscriptionToAddress(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _owner
    ) public returns (uint256) {
        return
            _createSubscription(_name, _price, _owner, _interval, USDC_ADDRESS);
    }

    function createTokenSubscription(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _token
    ) public returns (uint256) {
        return
            _createSubscription(_name, _price, msg.sender, _interval, _token);
    }

    function createTokenSubscriptionToAddress(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _token,
        address _owner
    ) public returns (uint256) {
        return _createSubscription(_name, _price, _owner, _interval, _token);
    }

    function subscribe(uint256 _id) public returns (uint256) {
        Option memory sub = options[_id];
        require(sub.active, "Subscription type is not active");
        require(
            sub.owner != msg.sender,
            "You cannot subscribe to your own subscription"
        );
        _pay(sub.token, sub.owner, sub.price);
        subscriptions[lastSubscription] = Subscription({
            id: _id,
            active: true,
            owner: msg.sender,
            lastPayment: block.timestamp
        });
        emit SubscriptionCreated(lastSubscription - 1, sub.interval);
        unchecked {
            ++lastSubscription;
        }
        return lastSubscription - 1;
    }

    function unsubscribe(uint256 _id) public {
        Subscription memory sub = subscriptions[_id];
        require(sub.active);
        require(sub.owner == msg.sender || owner == msg.sender);
        sub.active = false;
        subscriptions[_id] = sub;
        emit SubscriptionDestroyed(_id);
    }

    function pay(uint256 _id) public {
        Subscription memory sub = subscriptions[_id];
        Option memory opt = options[sub.id];
        require(sub.active, "Subscription has been deactivated");
        require(
            block.timestamp - sub.lastPayment >= opt.interval,
            "Payment not due"
        );
        uint256 num = opt.price * (block.timestamp - sub.lastPayment);
        uint256 toBePaid = _divide(num, opt.interval);
        _pay(opt.token, opt.owner, toBePaid, sub.owner);
        emit SubscriptionPaid(_id, toBePaid, msg.sender);
        sub.lastPayment = block.timestamp;
    }

    function _divide(uint256 num1, uint256 num2)
        private pure
        returns (uint256 result)
    {
        assembly {
            result := div(num1, num2)
        }
    }

    function getSubscription(uint256 _id)
        public
        view
        returns (Subscription memory)
    {
        return subscriptions[_id];
    }

    function getOption(uint256 _id) public view returns (Option memory) {
        return options[_id];
    }

    function getAllOptions() public view returns (Option[] memory) {
        Option[] memory res = new Option[](last);
        for (uint256 i = 0; i < last; ++i) {
            res[i] = options[i];
        }
        return res;
    }

    function getAllSubscriptions() public view returns (Subscription[] memory) {
        Subscription[] memory res = new Subscription[](lastSubscription);
        for (uint256 i = 0; i < lastSubscription; ++i) {
            res[i] = subscriptions[i];
        }
        return res;
    }

    function changeOwner(address _newOwner) public {
        require(owner == msg.sender);
        owner = _newOwner;
    }

    function changeOptionOwner(uint256 _id, address _newOwner) public {
        Option memory opt = options[_id];
        require(opt.owner == msg.sender || owner == msg.sender);
        opt.owner = _newOwner;
        options[_id] = opt;
    }

    function disableOption(uint256 _id) public {
        Option memory opt = options[_id];
        require(opt.owner == msg.sender || owner == msg.sender);
        opt.active = false;
        options[_id] = opt;
    }

    function _pay(
        address token,
        address to,
        uint256 price,
        address from
    ) private {
        IERC20 USDC = IERC20(token);
        require(
            USDC.transferFrom(from, to, price),
            "Failed to pay. Approval required?"
        );
    }

    function _pay(
        address token,
        address to,
        uint256 price
    ) private {
        IERC20 USDC = IERC20(token);
        require(
            USDC.transferFrom(msg.sender, to, price),
            "Failed to pay. Approval required?"
        );
    }

    function _createSubscription(
        string memory _name,
        uint256 _price,
        address _owner,
        uint256 _interval,
        address _token
    ) private returns (uint256) {
        Option memory opt = Option({
            name: _name,
            price: _price,
            active: true,
            owner: _owner,
            interval: _interval,
            token: _token
        });
        require(opt.interval != 0, "interval cannot be 0");
        require(opt.price != 0, "price cannot be 0");
        options[last] = opt;
        unchecked {
            ++last;
        }
        return last - 1;
    }
}
