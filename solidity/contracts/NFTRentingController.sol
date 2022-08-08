
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./INFTDelegatableCollection.sol";

contract NFTRentingController {

  ////////////////////////////////////////////////////////////////////////////////
  // DATA STRUCTURES
  ////////////////////////////////////////////////////////////////////////////////

  struct Listing {
    uint256 nonce;
    address ownerAddress;
    uint256 hourlyRate;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // EVENTS
  ////////////////////////////////////////////////////////////////////////////////

  event ItemListed(address nftCollectionAddress, uint256 nftTokenId, address ownerAddress, uint256 hourlyRate);
  event ItemUnlisted(address nftCollectionAddress, uint256 nftTokenId);
  event ItemRent(address nftCollectionAddress, uint256 nftTokenId, address userAddress, uint256 amount, uint256 expires);

  ////////////////////////////////////////////////////////////////////////////////
  // STORAGE VARIABLES
  ////////////////////////////////////////////////////////////////////////////////

  uint256 private _lastListingNonce = 0;
  mapping(address => mapping(uint256 => Listing)) private _listings;

  ////////////////////////////////////////////////////////////////////////////////
  // FUNCTIONS
  ////////////////////////////////////////////////////////////////////////////////

  function listItem(address _collectionAddress, uint256 _tokenId, uint256 _hourlyRate) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce == 0, "Item already listed");
    require (_hourlyRate > 0, "Invalid hourly rate");

    INFTDelegatableCollection nftCollection = INFTDelegatableCollection(_collectionAddress);

    require (nftCollection.ownerOf(_tokenId) == msg.sender, "User does not own this NFT");
    // TODO: check if INFTDelegatableCollection interface is indeed supported.

    nftCollection.transferFrom(msg.sender, address(this), _tokenId);

    _lastListingNonce++;

    listing.nonce = _lastListingNonce;
    listing.ownerAddress = msg.sender;
    listing.hourlyRate = _hourlyRate;

    emit ItemListed(_collectionAddress, _tokenId, msg.sender, _hourlyRate);
  }

  function unlistItem(address _collectionAddress, uint256 _tokenId) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce > 0, "Listing not available");
    require (listing.ownerAddress == msg.sender, "Caller is not the NFT owner");

    INFTDelegatableCollection(_collectionAddress).transferFrom(address(this), listing.ownerAddress, _tokenId);

    delete _listings[_collectionAddress][_tokenId];
    emit ItemUnlisted(_collectionAddress, _tokenId);
  }

  function rentItem(address _collectionAddress, uint256 _tokenId, uint256 _hours, uint256 _amount) external {
    Listing storage listing = _listings[_collectionAddress][_tokenId];
    require (listing.nonce > 0, "Listing not available");
    require (listing.ownerAddress != msg.sender, "Caller cannot be the NFT owner");

    uint256 hourlyRate = listing.hourlyRate;
    uint256 totalAmount = _hours * hourlyRate;
    require (totalAmount == _amount, "Incorrect amount");

    address currentUser = INFTDelegatableCollection(_collectionAddress).userOf(_tokenId);
    require (currentUser == address(0x0), "NFT is currently rent to another user");

    // TODO: take fee and transfer net amount to NFT owner.
    // ...

    // For testing: use seconds instead of hours.
    // uint256 expires = block.timestamp + _hours * 3600;
    uint256 expires =  block.timestamp + _hours;
    INFTDelegatableCollection(_collectionAddress).setUser(_tokenId, msg.sender, expires);

    emit ItemRent(_collectionAddress, _tokenId, msg.sender, totalAmount, expires);
  }
}
