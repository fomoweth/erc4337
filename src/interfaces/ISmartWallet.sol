// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAccessControl} from "./account/IAccessControl.sol";
import {IBaseAccount} from "./account/IBaseAccount.sol";

interface ISmartWallet is IBaseAccount, IAccessControl {}
