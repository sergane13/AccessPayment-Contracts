// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "./Access.sol";

/**
 * @title Contract that process payments from users
 * @author Runus team
 * @notice Access contract required
 * @dev Current contract has close ties with the Access contract. Please set one.
 * Services and accumulated money are stored here. Manager has to manualy withdraw the cash.
 * Contract calls automaticaly the access contract after payment received.
*/
contract Payment
{   
    event ServiceCreated(uint256 id, uint248 price);
    event ServiceStarted(uint256 id);
    event ServiceStoped(uint256 id);

    uint256 private _servicesIndex;

    enum PaymentFreq{ONETIME, MONTHLY, YEARLY}

    struct Service{
        bool isActive;
        uint248 price;
        PaymentFreq freq;
    }

    mapping(uint256 => Service) _services;

    address private _owner;
    Access private _accessContract;

    /**
     *
    */
    modifier onlyOwner()
    {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    /**
     *
    */
    modifier nonZeroAddress(address _sender)
    {
        require(_sender != address(0), "No zero address");
        _;
    }

    /**
     *
    */
    modifier serviceExists(uint256 _id)
    {
        require(_id < _servicesIndex, "Service does not exists");
        _;
    }

    /**
     *
    */
    modifier serviceRunning(uint256 _id)
    {
        require(_services[_id].isActive == true, "Service is stopped");
        _;
    }

    /**
     *
    */
    modifier serviceStopped(uint256 _id)
    {
        require(_services[_id].isActive == false, "Service is running");
        _;
    }

    /**
     *
    */
    modifier correctPrice(uint256 _id)
    {
         require(_services[_id].price == msg.value, "Invalid Payment");
         _;
    }

    // CONTRACT ACCESS MUST HAVE CODE
    constructor(address accessContract_) 
        nonZeroAddress(accessContract_)
    {
        _servicesIndex = 0;
        _owner = msg.sender;
        _accessContract = Access(accessContract_);
    }

    /**
     * @dev Create service for business.
    */
    function CreateService(
        uint248 _price, 
        PaymentFreq _freq
    )   external 
        onlyOwner 
    {
        _services[_servicesIndex].isActive = true;
        _services[_servicesIndex].price = _price;
        _services[_servicesIndex].freq = _freq;

        _servicesIndex = _servicesIndex + 1;
    }

    /**
     * @dev Start an inactive service.
    */
    function StartService(
        uint256 _id
    ) 
        external 
        onlyOwner
        serviceExists(_id)
        serviceStopped(_id)
    {
        _services[_id].isActive = true;
    }

    /**
     * @dev Stop an active service.
    */
    function StopService(
        uint256 _id
    ) 
        external
        onlyOwner 
        serviceExists(_id)
        serviceRunning(_id)
    {
        _services[_id].isActive = false;
    }

    /**
     * @dev Change price of a service no matter 
     * service status [active, stopped].
     * Modifications will rull up after users access expires.
    */
    function ChangeServicePrice(
        uint256 _id, 
        uint248 _price
    ) 
        external 
        onlyOwner 
        serviceExists(_id)
    {
        _services[_id].price = _price;
    }

    /**
     * @dev Change payment frequency for service.
     * Modifications will rull up after users access expires.
    */
    function ChangeServiceFreq(
        uint256 _id, 
        PaymentFreq _freq
    ) 
        external
        onlyOwner
        serviceExists(_id) 
    {
        _services[_id].freq = _freq;
    }


    /**
     *
    */
    function PayService(
        uint256 _id
    ) 
        external payable 
        serviceExists(_id)
        serviceRunning(_id)
        correctPrice(_id)
    {
    
       
    
    }

    /**
     *
    */
    function PayServiceFrom() external payable {}
    
    /**
     *
    */
    function ChangeAccessContract() external {}

    /**
     *
    */
    function WithdrawFunds() external {}

    /**
     *
    */
    function _payService(uint256 _id, address _client) internal {
        Service memory _service = _services[_id];
        _accessContract.GiveAccess(_id, _client, _expirationTime(_service.freq));
    }

    /**
     *
    */
    function _expirationTime(PaymentFreq _freq) internal view returns(uint248){

        uint248 _now = uint248(block.timestamp);

        if(_freq == PaymentFreq.ONETIME){
            return _now + 36500 days;
        }else if(_freq == PaymentFreq.MONTHLY){
            return _now + 30 days;
        }else if(_freq == PaymentFreq.YEARLY){
            return _now + 365 days;
        }   
    }
}
