%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_lt, uint256_mul
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_timestamp

from openzeppelin.security.safemath import uint256_checked_add, uint256_checked_sub_le
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from INFTDelegatableCollection import INFTDelegatableCollection

##################################################################
# DATA STRUCTURES
##################################################################

struct Listing:
    member nonce: Uint256
    member ownerAddress: felt
    member hourlyRate: Uint256
end

##################################################################
# EVENTS
##################################################################

@event
func ItemListed(nftCollectionAddress: felt, nftTokenId: Uint256, ownerAddress: felt, hourlyRate: Uint256):
end

@event
func ItemUnlisted(nftCollectionAddress: felt, nftTokenId: Uint256):
end

@event
func ItemRent(nftCollectionAddress: felt, nftTokenId: Uint256, userAddress: felt, amount: Uint256, expires: felt):
end

##################################################################
# STORAGE VARIABLES
##################################################################

@storage_var
func _lastListingNonce() -> (lastListingNonce: Uint256):
end

@storage_var
func _listings(nftCollectionAddress: felt, nftTokenId: Uint256) -> (listing: Listing):
end

##################################################################
# FUNCTIONS
##################################################################

@external
func listItem{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (_nftCllectionAddress: felt, _nftTokenId: Uint256, _hourlyRate: Uint256):

    alloc_locals

    uint256_check(_nftTokenId)
    uint256_check(_hourlyRate)

    let (caller) = get_caller_address()
    let (this) = get_contract_address()    

    let (listing) = _listings.read(_nftCllectionAddress, _nftTokenId)
    let (newListing) = uint256_eq(Uint256(0,0), listing.nonce)
    with_attr error_message("Item already listed"):
        assert newListing = 1
    end

    let (rateOk) = uint256_lt(Uint256(0, 0), _hourlyRate)
    with_attr error_message("Invalid hourly rate"):
         assert rateOk = 1
    end

    let (tokenOwner) = IERC721.ownerOf(contract_address=_nftCllectionAddress, tokenId=_nftTokenId) 
    with_attr error_message("User does not own this NFT"):
        assert caller = tokenOwner
    end

    # TODO: check if INFTDelegatableCollection interface is indeed supported.

    IERC721.transferFrom(contract_address=_nftCllectionAddress, _from=caller, to=this, tokenId=_nftTokenId)

    let (lastListingNonce) = _lastListingNonce.read()
    let (nextListingNonce) = uint256_checked_add(lastListingNonce, Uint256(1,0))
    _listings.write(_nftCllectionAddress, _nftTokenId, Listing(nextListingNonce, caller, _hourlyRate))
    _lastListingNonce.write(nextListingNonce)

    ItemListed.emit(_nftCllectionAddress, _nftTokenId, caller, _hourlyRate)
    return()
end

@external
func unlistItem{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (_nftCollectionAddress: felt, _nftTokenId: Uint256):

    alloc_locals

    uint256_check(_nftTokenId)

    let (caller) = get_caller_address()
    let (this) = get_contract_address()    

    let (listing) = _listings.read(_nftCollectionAddress, _nftTokenId)
    let (listingExists) = uint256_lt(Uint256(0,0), listing.nonce)
    with_attr error_message("Listing not available"):
        assert listingExists = 1
    end

    with_attr error_message("Caller is not the NFT owner"):
         assert listing.ownerAddress = caller
    end

    IERC721.transferFrom(contract_address=_nftCollectionAddress, _from=this, to=listing.ownerAddress, tokenId=_nftTokenId)

    _listings.write(_nftCollectionAddress, _nftTokenId, Listing(Uint256(0,0), 0, Uint256(0, 0)))

    ItemUnlisted.emit(_nftCollectionAddress, _nftTokenId)
    return ()
end

@external
func rentItem{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (_nftCollectionAddress: felt, _nftTokenId: Uint256, _hours: felt, _amount: Uint256):

    alloc_locals

    uint256_check(_nftTokenId)
    uint256_check(_amount)

    let (caller) = get_caller_address()
    let (this) = get_contract_address()
    let (timestamp) = get_block_timestamp()    

    let (listing) = _listings.read(_nftCollectionAddress, _nftTokenId)
    let (listingExists) = uint256_lt(Uint256(0,0), listing.nonce)
    with_attr error_message("Listing not available"):
        assert listingExists = 1
    end

    tempvar callerIsOwner = 0
    if listing.ownerAddress == caller:
        callerIsOwner = 1        
    end

    with_attr error_message("Caller cannot be the NFT owner"):
         assert callerIsOwner = 0
    end

    let (local totalAmount, carry) = uint256_mul(Uint256(_hours, 0), listing.hourlyRate)
    assert carry = Uint256(0, 0)
    let (check_lower_bound_1) = uint256_lt(Uint256(_hours,0), totalAmount)
    assert check_lower_bound_1 = 1
    let (check_lower_bound_2) = uint256_lt(listing.hourlyRate, totalAmount)
    assert check_lower_bound_2 = 1
    let (amountOK) = uint256_eq(totalAmount, _amount)
    with_attr error_message("Incorrect amount"):
         assert amountOK = 1
    end

    let (tokenUser) = INFTDelegatableCollection.userOf(contract_address=_nftCollectionAddress, tokenId=_nftTokenId) 
    with_attr error_message("NFT is currently rent to another user"):
        assert tokenUser = 0
    end

    # TODO: take fee and transfer net amount to NFT owner.
    # ...

    # For testing: use seconds instead of hours.
    # uint256 expires = block.timestamp + _hours * 3600;
    tempvar expires = timestamp +  _hours
    INFTDelegatableCollection.setUser(contract_address=_nftCollectionAddress, tokenId=_nftTokenId, user=caller, expires=expires) 

    ItemRent.emit(_nftCollectionAddress, _nftTokenId, caller, totalAmount, expires)
    return ()
end
