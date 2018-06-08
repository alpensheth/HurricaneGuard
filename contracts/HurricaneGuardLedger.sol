/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Ledger contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardAccessControllerInterface.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardLedgerInterface.sol";
import "./HurricaneGuardConstants.sol";

contract HurricaneGuardLedger is HurricaneGuardControlledContract, HurricaneGuardLedgerInterface, HurricaneGuardConstants {
  HurricaneGuardDatabaseInterface HG_DB;
  HurricaneGuardAccessControllerInterface HG_AC;

  function HurricaneGuardLedger(address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HG_AC = HurricaneGuardAccessControllerInterface(getContract("HG.AccessController"));
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));

    HG_AC.setPermissionById(101, "HG.NewPolicy");
    HG_AC.setPermissionById(101, "HG.Controller"); // todo: check!

    HG_AC.setPermissionById(102, "HG.Payout");
    HG_AC.setPermissionById(102, "HG.NewPolicy");
    HG_AC.setPermissionById(102, "HG.Controller"); // todo: check!
    HG_AC.setPermissionById(102, "HG.Underwrite");
    HG_AC.setPermissionById(102, "HG.Owner");

    HG_AC.setPermissionById(103, "HG.Funder");
    HG_AC.setPermissionById(103, "HG.Underwrite");
    HG_AC.setPermissionById(103, "HG.Payout");
    HG_AC.setPermissionById(103, "HG.Ledger");
    HG_AC.setPermissionById(103, "HG.NewPolicy");
    HG_AC.setPermissionById(103, "HG.Controller");
    HG_AC.setPermissionById(103, "HG.Owner");

    HG_AC.setPermissionById(104, "HG.Funder");
  }

  /*
   * @dev Fund contract
   */
  function fund() payable {
    require(HG_AC.checkPermission(104, msg.sender));

    bookkeeping(Acc.Balance, Acc.RiskFund, msg.value);

    // todo: fire funding event
  }

  function receiveFunds(Acc _to) payable {
    require(HG_AC.checkPermission(101, msg.sender));

    LogReceiveFunds(msg.sender, uint8(_to), msg.value);

    bookkeeping(Acc.Balance, _to, msg.value);
  }

  function sendFunds(address _recipient, Acc _from, uint _amount) returns (bool _success) {
    require(HG_AC.checkPermission(102, msg.sender));

    if (this.balance < _amount) {
      return false; // unsufficient funds
    }

    LogSendFunds(_recipient, uint8(_from), _amount);

    bookkeeping(_from, Acc.Balance, _amount); // cash out payout

    if (!_recipient.send(_amount)) {
      bookkeeping(Acc.Balance, _from, _amount);
      _success = false;
    } else {
      _success = true;
    }
  }

  // invariant: acc_Premium + acc_RiskFund + acc_Payout + acc_Balance + acc_Reward + acc_OraclizeCosts == 0

  function bookkeeping(Acc _from, Acc _to, uint256 _amount) {
    require(HG_AC.checkPermission(103, msg.sender));

    // check against type cast overflow
    assert(int256(_amount) > 0);

    // overflow check is done in FD_DB
    HG_DB.setLedger(uint8(_from), -int(_amount));
    HG_DB.setLedger(uint8(_to), int(_amount));
  }
}
