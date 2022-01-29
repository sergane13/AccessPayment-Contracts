// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity 0.8.11;

/**
 * @title Contract that stores users permission for different services of a business
 * @author Runus team
 * @notice PaymentContract required.
 * @dev Current contract has close ties with the Payment contract. Please set one.
*/
contract Access
{   
    event AccessGiven(uint256 service, address indexed client, uint256 expirationDate);
    event AccessRetrieved(uint256 service, address indexed client);

    address private _paymentContract;
    address private _owner;

    struct AccessDetails
    {
        bool hasAccess;
        uint248 expirationTime;
    }

    mapping(uint256 => mapping(address => AccessDetails)) private _accessManagement;
    
    /**
     * @dev Throws if called by an account that is not the owner of the payment contract.
    */
    modifier onlyManagers()
    {
        require(msg.sender == _owner || msg.sender == _paymentContract, "Only owner");
        _;
    }

    /**
     * @dev Throws if sender is 0 address.
    */
    modifier nonZeroAddress(address _sender)
    {
        require(_sender != address(0), "No zero address");
        _;
    }

    /**
     * @dev Throws if client has no access.
    */
    modifier hasAccess(uint256 _service, address _client)
    {
        require(_accessManagement[_service][_client].hasAccess == true, "He has no access");
        _;
    }

    /**
     * @dev Throws if client has access.
    */
    modifier hasNoAccess(uint256 _service, address _client)
    {
        require(_accessManagement[_service][_client].hasAccess == false, "He has access");
        _;
    }

    /**
     * @dev Throws if date is before curent time.
    */
    modifier expirationDate(uint256 _date)
    {
        require(_date > _getCurrentTime(), "Old expiration date");
        _;
    }

    /**
     * @dev Set owner of the account.
    */
    constructor(){
        _owner = msg.sender;
    }
    
    /**
     * @dev Offer access to client for the specified service.
    */
    function giveAccess(
        uint256 _service, 
        address _client, 
        uint248 _expirationDate
    ) 
        external 
        onlyManagers 
        nonZeroAddress(_client) 
        hasNoAccess(_service, _client)
        expirationDate(_expirationDate)
    {
        _giveAccess(_service, _client, _expirationDate);
    } 

    /**
     * @dev Retrieve access of the client for the specified service.
    */
    function retrieveAccess(
        uint256 _service, 
        address _client) 
        external 
        onlyManagers 
        nonZeroAddress(_client)
        hasAccess(_service, _client)
    {
        _retrieveAccess(_service, _client);
    } 

    /**
     * @dev Verify access of the client and retrieve it if expiration date has passed.
    */
    function verifyAccess(
        uint256 _service, 
        address _client
    ) 
        external 
        onlyManagers 
        nonZeroAddress(_client)
        hasAccess(_service, _client)
    {  
        AccessDetails memory tempAccess = _accessManagement[_service][_client];

        if(tempAccess.expirationTime > _getCurrentTime())
        {
            _retrieveAccess(_service, _client);
        }
    } 
    
    /**
     * @dev Set a payment contract that will comunicate with this one.
    */
    function setPaymentContract(
        address _newPaymentContract
    ) 
        external 
        onlyManagers 
        nonZeroAddress(_newPaymentContract)
    {   
        _paymentContract = _newPaymentContract;
    }

    /**
     * @dev Return client access for a service.
    */
    function getAccess(
        uint256 _service, 
        address _client
    ) 
        external view
        returns(bool)
    {
        return _accessManagement[_service][_client].hasAccess;
    } 

    /**
     * @dev Return expiration date of a client for a service.
    */
    function getExpirationDate(
        uint256 _service, 
        address _client
    )
        external view
        returns(uint256)
    {
        return _accessManagement[_service][_client].expirationTime;
    } 

    /**
     * @dev Return owner of the contract.
    */
    function getOwner()
        external view
        returns(address)
    {
        return _owner;
    }

    /**
     * @dev Return payment contract connected to this contract.
    */
    function getPaymentContract()
        external view
        returns(address)
    {
         return _paymentContract;
    }

    /**
     * @dev Offer access to client for the specified service.
     * Internal function without access restriction.
    */
    function _giveAccess(
        uint256 _service, 
        address _client,
        uint248 _expirationDate
    ) 
        internal 
    {
        _accessManagement[_service][_client].hasAccess = true;
        _accessManagement[_service][_client].expirationTime = _expirationDate;

        emit AccessGiven(_service, _client, _expirationDate);
    }

    /**
     * @dev Retrieve access of the client for the specified service.
     * Internal function without access restriction.
    */
    function _retrieveAccess(
        uint256 _service, 
        address _client
    ) 
        internal 
    {
        _accessManagement[_service][_client].hasAccess = false;
        _accessManagement[_service][_client].expirationTime = 0;

        emit AccessRetrieved(_service, _client);
    }

    /**
     * @dev Return current time for verifications.
     * Due to higher timeframe used in this contract,
     * block.timestamp is a good approach to verify variables.
     * Timestamp manipulation is not significant for our usecase.
    */
    function _getCurrentTime() internal view returns(uint256)
    {
        return block.timestamp;
    }
}