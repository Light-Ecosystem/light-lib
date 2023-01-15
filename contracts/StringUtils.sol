// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

library StringUtils {
    // This code has not been professionally audited, therefore I cannot make any promises about
    // safety or correctness. Use at own risk.
    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}
