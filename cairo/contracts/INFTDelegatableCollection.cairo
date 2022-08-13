# SPDX-License-Identifier: MIT
# OpenZeppelin Cairo Contracts v0.1.0 (token/erc721/interfaces/IERC721.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.IERC165 import IERC165

@contract_interface
namespace INFTDelegatableCollection:
  func setUser(tokenId: Uint256, user: felt, expires: felt):
  end

  func userOf(tokenId: Uint256) -> (address: felt):
  end

  func userExpires(tokenId: Uint256) -> (expires: felt):
  end
end
