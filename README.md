
## Token Data IPFS Uploader
This application will take the NFT image and metadata in the `img` and `metadata` folders respectively and match the name of the `.gif` to the name of the `.json` file and upload and pin the data to the Infura IPFS pinning service.

#### Quick Start
```
npm install
npm start
```
Output file will be `tokenData.json`, data is a json array with each element having an object `imageHash` and `metadataHash` representing the uploaded version of the respective files.

#### Todo
- [ ] Update the one tof the tokens JSON and image
- [ ] Import `tokenData.json` into migration script 