//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// create a smart contract that lets anyone create monthly subscriptions and lets other users pay for it monthly in USDC

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

    mapping(uint256 => Option) public options;
    mapping(uint256 => Subscription) public subscriptions;

    constructor() {
        last = 0;
        owner = msg.sender;
    }

    function createUsdcSubscription(
        string memory _name,
        uint256 _price,
        uint256 _interval
    ) public returns (uint256) {
        Option memory opt = Option({
            name: _name,
            price: _price,
            active: true,
            owner: msg.sender,
            interval: _interval,
            token: 0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5
        });
        require(opt.interval != 0);
        require(opt.price != 0);
        options[last] = opt;
        last++;
        return last - 1;
    }

    function createUsdcSubscriptionToAddress(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _owner
    ) public returns (uint256) {
        Option memory opt = Option({
            name: _name,
            price: _price,
            active: true,
            owner: _owner,
            interval: _interval,
            token: 0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5
        });
        require(opt.interval != 0);
        require(opt.price != 0);
        options[last] = opt;
        last++;
        return last - 1;
    }

    function createTokenSubscription(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _token
    ) public returns (uint256) {
        Option memory opt = Option({
            name: _name,
            price: _price,
            active: true,
            owner: msg.sender,
            interval: _interval,
            token: _token
        });
        require(opt.interval != 0);
        require(opt.price != 0);
        options[last] = opt;
        last++;
        return last - 1;
    }

    // pay to a different address

    function createTokenSubscriptionToAddress(
        string memory _name,
        uint256 _price,
        uint256 _interval,
        address _token,
        address _owner
    ) public returns (uint256) {
        Option memory opt = Option({
            name: _name,
            price: _price,
            active: true,
            owner: _owner,
            interval: _interval,
            token: _token
        });
        require(opt.interval != 0);
        require(opt.price != 0);
        options[last] = opt;
        last++;
        return last - 1;
    }

    function subscribe(uint256 _id) public returns (uint256) {
        Option memory sub = options[_id];
        require(sub.active);
        require(sub.owner != msg.sender);
        IERC20 USDC = IERC20(0x2F375e94FC336Cdec2Dc0cCB5277FE59CBf1cAe5);
        require(USDC.transferFrom(msg.sender, sub.owner, sub.price));
        subscriptions[lastSubscription] = Subscription({
            id: _id,
            active: true,
            owner: msg.sender,
            lastPayment: block.timestamp
        });
        lastSubscription++;
        return lastSubscription - 1;
    }

    function unsubscribe(uint256 _id) public {
        Subscription memory sub = subscriptions[_id];
        require(sub.active);
        require(sub.owner == msg.sender || owner == msg.sender);
        delete subscriptions[_id];
    }

    function pay(uint256 _id) public {
        Subscription memory sub = subscriptions[_id];
        Option memory opt = options[sub.id];
        require(sub.active);
        require(block.timestamp - sub.lastPayment >= opt.interval);
        IERC20 USDC = IERC20(opt.token);
        require(
            USDC.transferFrom(
                sub.owner,
                owner,
                (opt.price * (block.timestamp - sub.lastPayment)) / opt.interval
            )
        );
        sub.lastPayment = block.timestamp;
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

    function getOptions() public view returns (Option[] memory) {
        Option[] memory res = new Option[](last);
        for (uint256 i = 0; i < last; i++) {
            res[i] = options[i];
        }
        return res;
    }

    function getSubscriptions() public view returns (Subscription[] memory) {
        Subscription[] memory res = new Subscription[](lastSubscription);
        for (uint256 i = 0; i < lastSubscription; i++) {
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


}
