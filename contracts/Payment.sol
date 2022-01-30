// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
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
    event ServiceCreated(uint256 indexed id, uint248 price);
    event ServiceStarted(uint256 indexed id);
    event ServiceStoped(uint256 indexed id);

    uint256 private _servicesIndex;

    enum PaymentFreq{ONETIME, MONTHLY, YEARLY}

    struct Service{
        bool isActive;
        uint232 price;
        PaymentFreq freq;
    }

    mapping(uint256 => Service) private _services;

    address private _owner;
    Access private _accessContract;

    /**
     * @dev Throw if not owner
    */
    modifier onlyOwner()
    {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    /**
     * @dev Throw if address is 0 address
    */
    modifier nonZeroAddress(address _sender)
    {
        require(_sender != address(0), "No zero address");
        _;
    }

    /**
     * @dev Throw if service does not exist yet
    */
    modifier serviceExists(uint256 _id)
    {
        require(_id < _servicesIndex, "Service does not exists");
        _;
    }

    /**
     * @dev Throw if service is stopped
    */
    modifier serviceRunning(uint256 _id)
    {
        require(_services[_id].isActive == true, "Service is stopped");
        _;
    }

    /**
     * @dev Throw if service is started
    */
    modifier serviceStopped(uint256 _id)
    {
        require(_services[_id].isActive == false, "Service is running");
        _;
    }

    /**
     * @dev Throw if contract has no funds
    */
    modifier contractBalance()
    {
        require(address(this).balance > 0, "No funds");
        _;
    }

    /**
     * @dev init the owner, service index and the access contract that will 
     * comunicate with this one
    */
    constructor(address accessContract_) 
        nonZeroAddress(accessContract_)
    {
        _servicesIndex = 0;
        _owner = msg.sender;
        _accessContract = Access(accessContract_);

        // CONTRACT ACCESS MUST HAVE CODE
    }

    /**
     * @dev Create service for business.
    */
    function createService(
        uint232 _price, 
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
    function startService(
        uint256 _id
    ) 
        external 
        onlyOwner
        serviceExists(_id)
        serviceStopped(_id)
    {
        _services[_id].isActive = true;

        emit ServiceStarted(_id);
    }  

    /**
     * @dev Stop an active service.
    */
    function stopService(
        uint256 _id
    ) 
        external 
        onlyOwner
        serviceExists(_id)
        serviceRunning(_id)
    {
        _services[_id].isActive = false;

        emit ServiceStoped(_id);
    }  

    /**
     * @dev Change price of a service no matter 
     * service status [active, stopped].
     * Modifications will rull up after users access expires.
    */
    function changeServicePrice(
        uint256 _id, 
        uint232 _price
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
    function changeServiceFreq(
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
     * @dev Client init a tx and pays for the service
    */
    function payService(
        uint256 _id
    ) 
        external payable 
        serviceExists(_id)
        serviceRunning(_id)
    {
       _payService(_id, msg.sender);
    }

    /**
     * @dev Someone pays a service for a friend
    */
    function payServiceFrom(
        uint256 _id, 
        address _client
    ) 
        external payable 
        serviceExists(_id)
        nonZeroAddress(_client)
        serviceRunning(_id)
    {
        _payService(_id, _client);
    }
    
    /**
     * @dev Modify the access contract that stores permissions
    */
    function changeAccessContract(
        address _newAccessContract
    ) 
        external
        onlyOwner
        nonZeroAddress(_newAccessContract)
    {
        _accessContract = Access(_newAccessContract);
    }

    /**
     * @dev Owner can withdraw funds stored in the contract.
     * The caller of the contract must be the owner who is an EOA;
    */
    function withdrawFunds() 
        external 
        onlyOwner
        contractBalance
    {   
        // replace here with send cause owner is EOA ??
        (bool sent, ) = _owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Money");
    }

    /**
     * @dev Get total number of services active and non active
    */
    function getNumberOfServices() 
        external view 
        returns(uint256)
    {
        return _servicesIndex;
    }

    /**
     * @dev Get details about a certain service
    */
    function getService(
        uint256 _id
    ) 
        external view 
        returns(
            bool, 
            uint248, 
            PaymentFreq
        )
    {
        return (
            _services[_id].isActive, 
            _services[_id].price, 
            _services[_id].freq
        );
    }

    /**
     * @dev Return the address of the owner
    */
    function getOwner() 
        external view 
        returns(address)
    {
        return _owner;
    }

    /**
     * @dev Return address of access contract
    */
    function getAccessContract() 
        external view 
        returns(address)
    {
        return address(_accessContract);
    }

    /**
     * @dev Pay service 
    */
    function _payService(
        uint256 _id, 
        address _client
    ) 
        internal 
    {
        Service memory _service = _services[_id];    

        require(_accessContract.getAccess(_id, _client) == false, "Access already given");
        require(_service.price == msg.value, "Invalid Payment");
        
        _accessContract.giveAccess(_id, _client, _expirationTime(_service.freq));
    }

    /**
     * @dev Get the expiration time for selected payment freq
    */
    function _expirationTime(
        PaymentFreq _freq
    ) 
        internal view 
        returns(uint248 _expTime)
    {
        uint248 _now = _getCurrentTime();

        if(_freq == PaymentFreq.ONETIME){
            _expTime = _now + 36500 days;
        }else if(_freq == PaymentFreq.MONTHLY){
            _expTime = _now + 30 days;
        }else if(_freq == PaymentFreq.YEARLY){
            _expTime = _now + 365 days;
        }   
    }

    /**
     * @dev Return current time for verifications.
     * Due to higher timeframe used in this contract,
     * block.timestamp is a good approach to verify variables.
     * Timestamp manipulation is not significant for our usecase.
    */
    function _getCurrentTime() internal view returns(uint248)
    {
        return uint248(block.timestamp);
    }
}