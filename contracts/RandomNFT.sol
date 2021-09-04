// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RandomNFT is ERC721, VRFConsumerBase, AccessControl {
    
    uint256 immutable MAX_INT = 2**256 - 1;
    address immutable _redeemToken;

    mapping(bytes32 => address) private requestIdToAddress;
    uint256 public fee;
    bytes32 public keyHash;

    string public baseURI = "ipfs://ipfs/";
    mapping(uint256 => string) tokenURIs;
    uint256[] public unclaimed;

    // 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
    // 0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    constructor (address redeemToken, address vrfCoordinator, address linkToken, string memory name, string memory symbol)
    ERC721(
        name,
        symbol
    )
    VRFConsumerBase(
        vrfCoordinator,
        linkToken
    ) {
        _setupRole("owner", msg.sender);
        _setupRole("steward", msg.sender);
        _redeemToken = redeemToken;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    modifier onlyOwner() {
        require(hasRole("owner", msg.sender), "RandomNFT.onlyOwner: caller is not the owner");
        _;
    }

    modifier onlySteward() {
        require(hasRole("steward", msg.sender), "RandomNFT.onlySteward: caller is not the steward");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal override(ERC721) view virtual returns (string memory) {
        return baseURI;
    }

    function redeemTokenForNFT() public {
        IERC20 token = IERC20(_redeemToken);
        uint256 balance = token.balanceOf(msg.sender) / 1e18;
        require(balance >= 1, "RandomNFT.redeemTokenForNFT: balance less than one");

        token.transferFrom(msg.sender, address(0), balance * 1e18);
        require(LINK.balanceOf(address(this)) >= fee * balance, "Not enough LINK - fill contract with faucet");
        for(uint256 i; i < balance; i++){
            requestIdToAddress[requestRandomness(keyHash, fee)] = msg.sender;
        }
    }

    function premint(uint256 tokenId, string memory tokenURI) public onlyOwner() {
        tokenURIs[tokenId] = tokenURI;
        _mint(address(this), tokenId);
        unclaimed.push(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _baseURI = _baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURIs[tokenId])) : "";
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override(VRFConsumerBase) {
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

    // fees for Chainlink VRF mioght change over time, so we need a method to update the fee
    function setFee(uint256 _fee) onlySteward() public {
        fee = _fee;
    }

    // method to recover unused LINK tokens
    function transferLink(address to, uint256 value) onlySteward() public {
        LINK.transfer(to, value);
    }
}
