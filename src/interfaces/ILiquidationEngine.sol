// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Dog
interface ILiquidationEngine {
    // chop
    function penalty(bytes32 collateral_type) external returns (uint256);
    // digs
    function removeDaiFromAuction(bytes32 collateral_type, uint256 rad)
        external;
}