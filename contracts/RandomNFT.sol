// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RandomNFT is ERC721, VRFConsumerBase, Ownable {
    mapping(address => bytes32[]) public addressToRequestId;

    address immutable _redeemToken;
    uint256 fee;
    bytes32 keyHash;

    mapping(uint256 => string) tokenURIs;

    constructor (address redeemToken) public
    ERC721("Random NFT", "$RAND")
    VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) {
        _redeemToken = redeemToken;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return "ipfs://ipfs/";
    }

    function redeemSeed() public {
        IERC20 token = IERC20(_redeemToken);
        uint256 balance = token.balanceOf(msg.sender) / 10 ** 18;

        token.transfer(address(0), balance);
        require(LINK.balanceOf(address(this)) >= fee * balance, "Not enough LINK - fill contract with faucet");
        for(uint256 i; i < balance; i++){
            addressToRequestId[msg.sender].push(requestRandomness(keyHash, fee));
        }
    }

    function batchMint(address[] memory to, uint256[] memory tokenId, string[] memory _tokenURI) onlyOwner public {
        for(uint256 i = 0; i < to.length; i++){
            mint(to[i], tokenId[i], _tokenURI[i]);
        }
    }

    function mint(address to, uint256 tokenId, string memory _tokenURI) onlyOwner public {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        tokenURIs[tokenId] = tokenURI;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // randomResult = randomness;
        // process the the random data to assign a tokenId
    }
}
