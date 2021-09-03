// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RandomNFT is ERC721, VRFConsumerBase, Ownable {
    
    uint256 immutable MAX_INT = 2**256 - 1;
    address immutable _redeemToken;

    mapping(bytes32 => address) private requestIdToAddress;
    uint256 private fee;
    bytes32 private keyHash;

    mapping(uint256 => string) tokenURIs;
    uint256[] private unclaimed;

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

    function redeemTokenForNFT() public {
        IERC20 token = IERC20(_redeemToken);
        uint256 balance = token.balanceOf(msg.sender) / 10 ** 18;

        token.transfer(address(0), balance);
        require(LINK.balanceOf(address(this)) >= fee * balance, "Not enough LINK - fill contract with faucet");
        for(uint256 i; i < balance; i++){
            requestIdToAddress[requestRandomness(keyHash, fee)] = msg.sender;
        }
    }

    function premint(uint256 tokenId, string memory tokenURI) public onlyOwner {
        tokenURIs[tokenId] = tokenURI;
        _mint(address(this), tokenId);
        unclaimed.push(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenURIs[tokenId])) : "";
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address to = requestIdToAddress[requestId];
        require(to == address(0), "fulfillRandomness: requestId does not exist");
        requestIdToAddress[requestId] = address(0);

        selectToken(to, randomness);
    }

    function selectToken(address to, uint256 randomness) internal {

        // reducing randomness to the same order as unclaimed
        // division will fail for divide by zero if the array is empty
        uint256 scale = MAX_INT / unclaimed.length;
        uint256 index = randomness / scale;
        uint256 tokenId = unclaimed[index];
        unclaimed[index] = 0;

        transferFrom(address(this), to, tokenId);
    }
}
