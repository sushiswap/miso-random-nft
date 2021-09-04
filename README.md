# Miso Random NFT
Miso random NFT is a contract that allows users to redeem a seed ERC20 (the token type sold on Miso) for a randomly selected ERC721 (NFT) using Chainlink VRF (verifiable random function). This contract is designed to allows a batch auction, dutch auction or crowd sale to occur on miso.sushi.com for an ERC20 seed and then the user can optionally reveal that seed. This process is more similar to a blind box or sealed pack for a collector.

Traditionally, NFT seeds have been sold in batches. This sale strategy suffers from a few faults.
- Post seed sale market can not develop
- Reveals are not provably random (can be manipulated)
- Group reveal forces all users to reveal seed simultaneously
- Value of the seed post reveal is changed

These contract work uni-directional (for saftey reasons) but a bi-directional system could also be created that allowed users to draw more than once.

The other portion of this repository is a tool to help with uploading metadata for ERC721s

## Token Data IPFS Uploader
This application will take the NFT image and metadata in the `img` and `metadata` folders respectively and match the name of the `.gif` to the name of the `.json` file and upload and pin the data to the Infura IPFS pinning service.

#### Quick Start
```
npm install
npm start
```
Output file will be `tokenData.json`, data is a json array with each element having an object `imageHash` and `metadataHash` representing the uploaded version of the respective files.
