//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./SchoolMagnet.sol";

contract MagnetAcademy is AccessControlEnumerable {
    using Counters for Counters.Counter;

    /**
     * @notice set up storage variable for roles with AccessControl. Here we don't use the DEFAULT_ADMIN_ROLE
     * but we could set the RECTOR_ROLE as the DEFAULT_ADMIN_ROLE.
     * Instead we set the RECTOR_ROLE as the administrator of the ADMIN_ROLE witch mean the rector can grant
     * and revoke admins
     *
     * @dev Severals role has admin role?
     * */
    bytes32 private constant _RECTOR_ROLE = keccak256("RECTOR_ROLE");
    bytes32 private constant _ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Counters.Counter private _nbSchools;
    mapping(address => address) private _schoolDirectors; // director to school
    mapping(address => address) private _schools; // school to director

    event AdminAdded(address indexed account);
    event AdminRevoked(address indexed account);
    event SchoolCreated(address indexed schoolAddress, address indexed directorAddress, string name);
    event SchoolDeleted(address indexed schoolAddress, address indexed directorAddress);
    event DirectorSet(address indexed directorAddress, address indexed schoolAddress);

    /**
     * @notice the modifier "OnlyRector" can be romoved because it was only used to set up admin role
     * The modifier "OnlyAdmin" is changed, it use now the function provided by AccessControl
     * */
    modifier OnlyAdmin() {
        require(hasRole(_ADMIN_ROLE, msg.sender), "MagnetAcademy: Only administrators can perform this action");
        _;
    }

    modifier OnlySchoolDirector(address account) {
        require(_schoolDirectors[account] != address(0), "MagnetAcademy: Not a school director");
        _;
    }

    modifier OnlyNotSchoolDirector(address account) {
        require(_schoolDirectors[account] == address(0), "MagnetAcademy: Already a school director");
        _;
    }

    modifier OnlySchoolAddress(address addr) {
        require(_schools[addr] != address(0), "MagnetAcademy: Only for created schools");
        _;
    }

    /**
     * @notice the role is set in the constructor as before the utilisation of AccessControl
     * In the constructor the RECTOR_ROLE is set has the admin role of ADMIN_ROLE witch mean
     * the RECTOR_ROLE can grant and revoke ADMIN_ROLE
     * */
    constructor(address rector_) {
        _setupRole(_RECTOR_ROLE, rector_);
        _setupRole(_ADMIN_ROLE, rector_);
        _setRoleAdmin(_ADMIN_ROLE, _RECTOR_ROLE);
    }

    /**
     * @notice the former modifier "OnlyRector" is removed since the RECTOR_ROLE is set to the admin of ADMIN_ROLE
     * is attribued to the rector. And only this latter can call the grant and the revoke role function.
     * */
    function addAdmin(address account) public {
        grantRole(_ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    function revokeAdmin(address account) public {
        revokeRole(_ADMIN_ROLE, account);
        emit AdminRevoked(account);
    }

    function changeSchoolDirector(address oldDirector, address newDirector)
        public
        OnlyAdmin()
        OnlySchoolDirector(oldDirector)
        OnlyNotSchoolDirector(newDirector)
        returns (bool)
    {
        address schoolAddress = _schoolDirectors[oldDirector];
        _schoolDirectors[oldDirector] = address(0);
        _schoolDirectors[newDirector] = schoolAddress;
        _schools[schoolAddress] = newDirector;
        emit DirectorSet(newDirector, schoolAddress);
        return true;
    }

    function createSchool(string memory name, address directorAddress)
        public
        OnlyAdmin()
        OnlyNotSchoolDirector(directorAddress)
        returns (bool)
    {
        SchoolMagnet school = new SchoolMagnet(directorAddress, name);
        _schoolDirectors[directorAddress] = address(school);
        _schools[address(school)] = directorAddress;
        emit DirectorSet(directorAddress, address(school));
        _nbSchools.increment();
        emit SchoolCreated(address(school), directorAddress, name);
        return true;
    }

    function deleteSchool(address schoolAddress) public OnlyAdmin() OnlySchoolAddress(schoolAddress) returns (bool) {
        address directorAddress = _schools[schoolAddress];
        _schools[schoolAddress] = address(0);
        _schoolDirectors[directorAddress] = address(0);
        _nbSchools.decrement();
        emit SchoolDeleted(schoolAddress, directorAddress);
        return true;
    }

    /**
     * @notice to see which address has which role we implement a new contract: AccessControlEnumerable.sol
     * But we don't need to set up a view function as it already definined in the ACE.sol
     *
     * But we need to have the byteCode of the role, so we set up getter to perform this
     *
     * @dev the function could be restricted to pure but this is a getter...
     * */

    function rectorRole() public view returns (bytes32) {
        return _RECTOR_ROLE;
    }

    function adminRole() public view returns (bytes32) {
        return _ADMIN_ROLE;
    }

    function nbSchools() public view returns (uint256) {
        return _nbSchools.current();
    }

    function schoolOf(address account) public view returns (address) {
        return _schoolDirectors[account];
    }

    function directorOf(address school) public view returns (address) {
        return _schools[school];
    }

    function isDirector(address account) public view returns (bool) {
        return _schoolDirectors[account] != address(0);
    }

    function isSchool(address addr) public view returns (bool) {
        return _schools[addr] != address(0);
    }
}
