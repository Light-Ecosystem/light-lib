// SPDX-License-Identifier: LGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./IPermit2.sol";

library TransferHelper {
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferIn(
        address permit2Address,
        address from,
        IPermit2.PermitTransferFrom memory permit,
        IPermit2.SignatureTransferDetails memory transferDetails,
        bytes memory signature
    ) internal returns (uint256) {
        // Read from storage once
        IERC20 token = IERC20(permit.permitted.token);
        uint256 balanceBefore = token.balanceOf(transferDetails.to);
        IPermit2(permit2Address).permitTransferFrom(permit, transferDetails, from, signature);
        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(permit.permitted.token).balanceOf(address(this));
        uint256 spendAmount = balanceAfter - balanceBefore;
        assert(spendAmount == transferDetails.requestedAmount);
        return spendAmount;
    }

    function doTransferInV2(
        address permit2Address,
        address token,
        uint256 _value,
        address from,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: token, amount: _value}),
            nonce: nonce,
            deadline: deadline
        });
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: _value
        });
        doTransferIn(permit2Address, from, permit, transferDetails, signature);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferOut(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of override external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
