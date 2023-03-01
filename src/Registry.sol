//SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registry {
    address public FACTORY_ADDRESS;
    // stores the proxies in a mapping(from user address to mapping(from index uint to proxy address))
    mapping(address => mapping(uint256 => address)) public registry;
    // stores the count of proxies for each user (starting from 1)
    mapping(address => uint256) public count;

    mapping(address => mapping(address => address)) public uniswapV3Pools;

    modifier onlyFactory() {
        require(msg.sender == FACTORY_ADDRESS, "Not factory");
        _;
    }

    constructor(address _factoryAddress) {
        FACTORY_ADDRESS = _factoryAddress;
    }

    function registerUniswapV3Pool(
        address token0,
        address token1,
        address pool
    ) public onlyFactory returns (bool) {
        uniswapV3Pools[token0][token1] = pool;
        return true;
    }

    function getUniswapV3Pool(address token0, address token1)
        external
        view
        returns (address)
    {
        return uniswapV3Pools[token0][token1];
    }

    // GETTERS:
    function getUserProxy(address user, uint256 index)
        public
        view
        returns (address)
    {
        return registry[user][index];
    }

    function getCount(address user) public view returns (uint256) {
        return count[user];
    }

    function registerUser(address user, address proxy)
        public
        onlyFactory
        returns (bool)
    {
        registry[user][getCount(user)] = proxy;
        count[user]++;
        return true;
    }
}
