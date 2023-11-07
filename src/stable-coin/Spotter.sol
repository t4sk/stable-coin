// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import "../lib/Math.sol";
import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";

// TODO: rename?
contract Spotter is Auth, CircuitBreaker {
    event Poke(bytes32 col_type, uint256 val, uint256 spot);

    // Ilk
    struct CollateralType {
        // pip
        IPriceFeed price_feed;
        // mat [ray]
        uint256 liquidation_ratio;
    }

    // ilks
    mapping(bytes32 => CollateralType) public cols;

    ICDPEngine public immutable cdp_engine;
    // par - value of DAI in the reference asset (e.g. $1 per DAI)
    uint256 public par; // ref per dai [ray]

    constructor(address _cdp_engine) {
        cdp_engine = ICDPEngine(_cdp_engine);
        par = RAY;
    }

    // file
    function set(bytes32 col_type, bytes32 key, address addr) external auth not_stopped {
        if (key == "price_feed") {
            cols[col_type].price_feed = IPriceFeed(addr);
        } else {
            revert("invalid param");
        }
    }

    function set(bytes32 key, uint256 val) external auth not_stopped {
        if (key == "par") {
            par = val;
        } else {
            revert("invalid param");
        }
    }

    function set(bytes32 col_type, bytes32 key, uint256 val) external auth not_stopped {
        if (key == "liquidation_ratio") {
            cols[col_type].liquidation_ratio = val;
        } else {
            revert("invalid param");
        }
    }

    function poke(bytes32 col_type) external {
        (uint256 val, bool ok) = cols[col_type].price_feed.peek();
        // TODO: should require ok?
        uint256 spot = ok
            // TODO: what?
            ? Math.rdiv(Math.rdiv(val * 10 ** 9, par), cols[col_type].liquidation_ratio)
            : 0;
        cdp_engine.set(col_type, "spot", spot);
        emit Poke(col_type, val, spot);
    }

    function stop() external auth {
        _stop();
    }
}
