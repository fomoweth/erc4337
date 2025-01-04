// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAccessControl} from "./wallet/IAccessControl.sol";
import {IBaseAccount} from "./wallet/IBaseAccount.sol";
import {IOwnable2Step} from "./wallet/IOwnable2Step.sol";

interface ISmartWallet is IBaseAccount, IAccessControl, IOwnable2Step {}
