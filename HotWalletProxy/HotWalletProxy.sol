// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ERC721Interface {
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
}

interface ERC1155Interface {
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
}

/**
 * Enables setting a hot wallet as a proxy for your cold wallet, so that you
 * can submit a transaction from your cold wallet once (or use a signature instead),
 * and other contracts can use this contract to map ownership of an ERC721 or ERC1155
 * token to your hot wallet.
 *
 * Example:
 *
 *   - Cold wallet 0x123 owns BAYC #456
 *   - Cold wallet 0x123 calls setHotWalletUsingTransaction(0xABC)
 *   - Another contract that wants to check for BAYC ownership calls ownerOf(BAYC_ADDRESS, 456);
 *     + This contract calls BAYC's ownerOf(456)
 *     + This contract will see that BAYC #456 is owned by 0x123, which is mapped to 0xABC, and
 *     + returns 0xABC from ownerOf(BAYC_ADDRESS, 456)
 *
 * NB: With balanceOf and balanceOfBatch, this contract will look up the balance of the cold
 * wallet, _ignoring anything the hot wallet holds_.
 */
contract HotWalletProxy {
  using ECDSA for bytes32;

  mapping(address => address) internal coldWalletToHotWallet;
  mapping(address => address) internal hotWalletToColdWallet;
  mapping(
    address => mapping(uint256 => bool)
  ) internal usedNonces;

  event HotWalletChanged(address coldWallet, address from, address to);

  function _setHotWallet(
    address coldWalletAddress,
    address hotWalletAddress
  )
  internal {
    address currentHotWalletAddress = coldWalletToHotWallet[coldWalletAddress];

    coldWalletToHotWallet[coldWalletAddress] = hotWalletAddress;

    if (hotWalletAddress == address(0)) {
      hotWalletToColdWallet[hotWalletAddress] = address(0);
    }
    else {
      hotWalletToColdWallet[hotWalletAddress] = coldWalletAddress;
    }

    emit HotWalletChanged(coldWalletAddress, currentHotWalletAddress, hotWalletAddress);
  }

  /**
   * Option 1: Submit a transaction from your cold wallet, thus verifying ownership
   * of the cold wallet.
   */
  function setHotWalletUsingTransaction(
    address hotWalletAddress
  )
  external
  {
    _setHotWallet(msg.sender, hotWalletAddress);
  }

  /**
   * Option 2: Submit a transaction from any wallet (including your hot wallet), with
   * a signature from your cold wallet to verify ownership of the cold wallet.
   *
   * Each nonce can only be used once to protect against replay attacks.
   *
   * NB: You should create the signature from an airgapped machine, or
   * otherwise take precautions not to leak your private key.
   */
  function setHotWalletUsingSignature(
    address coldWalletAddress,
    address hotWalletAddress,
    uint256 nonce,
    bytes calldata signature
  )
  external {
    _verifySignature(coldWalletAddress, hotWalletAddress, nonce, signature);

    usedNonces[coldWalletAddress][nonce] = true;

    _setHotWallet(coldWalletAddress, hotWalletAddress);
  }

  function _getSignatureSigner(
    bytes32 hash,
    bytes calldata signature
  )
  internal
  pure
  returns (address)
  {
    return hash.toEthSignedMessageHash().recover(signature);
  }

  function _verifySignature(
    address coldWalletAddress,
    address hotWalletAddress,
    uint256 nonce,
    bytes calldata signature
  )
  internal
  view
  {
    bool usedNonce = usedNonces[coldWalletAddress][nonce];
    require(usedNonce == false, "Nonce has already been used");

    address signer = _getSignatureSigner(
      keccak256(
        abi.encodePacked(
          nonce,
          hotWalletAddress
        )
      ),
      signature
    );
    require(signer == coldWalletAddress, "Signature isn't from cold wallet");
  }

  function getHotWallet(address coldWallet)
  external
  view
  returns (address)
  {
    return coldWalletToHotWallet[coldWallet];
  }

  function getColdWallet(address hotWallet)
  external
  view
  returns (address)
  {
    return hotWalletToColdWallet[hotWallet];
  }

  /**
   * ERC721 Methods
   */
  function balanceOf(
    address contractAddress,
    address owner
  )
  external
  view
  returns (
    uint256
  )
  {
    ERC721Interface erc721Contract = ERC721Interface(contractAddress);

    address coldWallet = hotWalletToColdWallet[owner];

    if (coldWallet != address(0)) {
      return erc721Contract.balanceOf(coldWallet);
    }

    return erc721Contract.balanceOf(owner);
  }

  function ownerOf(
    address contractAddress,
    uint256 tokenId
  )
  external
  view
  returns (
    address
  )
  {
    ERC721Interface erc721Contract = ERC721Interface(contractAddress);

    address owner = erc721Contract.ownerOf(tokenId);

    address hotWallet = coldWalletToHotWallet[owner];

    if (hotWallet != address(0)) {
      return hotWallet;
    }

    return owner;
  }

  /**
   * ERC1155 Methods
   */
  function balanceOfBatch(
    address contractAddress,
    address[] calldata owners,
    uint256[] calldata ids
  )
  external
  view
  returns(
    uint256[] memory
  )
  {
    uint256 ownersLength = owners.length;

    address[] memory mappedOwners = new address[](ownersLength);

    for (uint256 i = 0; i < ownersLength; i++) {
      address owner = owners[i];

      address coldWallet = hotWalletToColdWallet[owner];
      if (coldWallet != address(0)) {
        mappedOwners[i] = coldWallet;
      }
      else {
        mappedOwners[i] = owner;
      }
    }

    ERC1155Interface erc1155Contract = ERC1155Interface(contractAddress);

    return erc1155Contract.balanceOfBatch(mappedOwners, ids);
  }

  function balanceOf(
    address contractAddress,
    address owner,
    uint256 tokenId
  )
  external
  view
  returns (
    uint256
  )
  {
    ERC1155Interface erc1155Contract = ERC1155Interface(contractAddress);

    address coldWallet = hotWalletToColdWallet[owner];

    if (coldWallet != address(0)) {
      return erc1155Contract.balanceOf(coldWallet, tokenId);
    }

    return erc1155Contract.balanceOf(owner, tokenId);
  }
}
