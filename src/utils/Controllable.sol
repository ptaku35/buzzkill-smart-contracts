// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


/// @title Controllable
abstract contract Controllable {
    /// @notice address => is controller
    mapping(address => bool) private _isController;

    /// @notice Require the caller to be the controller
    modifier onlyController() {
        require(_isController[msg.sender], "Controller: Caller is not the controller");
        _;
    }

    /// @notice Check if address is a controller 
    function isController(address addr) public view returns (bool) {
        return _isController[addr];
    }

    /// @notice Set the state of the controller's address
    function _setController(address addr, bool state) internal {
        _isController[addr] = state;
    }
}