// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; //Imported in case burning NFTs is used
import "@openzeppelin/contracts/access/Ownable.sol";



    interface ITradeManagement{
        function Producer(address) external view returns(bool);
        function ProducerRawMaterialMapping(uint256) external view returns(address);
        function ProducerPackagedProductsMintingBalance(address, uint256) external view returns(uint256);
        function RawMaterialsSmartContract() external view returns(IERC721); //Returns the ERC721-compatible address of the raw materials smart contract
        function UpdateProducerMintingBalance(address, uint256, uint256) external;
        function LinkParentNFTtoChild1NFT(uint256, uint256) external;
    }

contract PackagedProducts is ERC721URIStorage, Ownable{
    uint public tokenCount;
    ITradeManagement public TradeManagement;
    constructor () ERC721("PackagedProducts", "PPS"){

    } 


    function SetTradeManagementSC(address _trademgmtsc) external onlyOwner{
        TradeManagement = ITradeManagement(_trademgmtsc);

    }

    function mint(string memory _tokenURI, uint256 _parentID) external returns(uint) {
        require(TradeManagement.Producer(msg.sender) == true, "Only authorized producer can mint packaged product NFT");
        require(TradeManagement.ProducerRawMaterialMapping(_parentID) == msg.sender, "The specified parent ID does not belong to the caller");
        require(TradeManagement.ProducerPackagedProductsMintingBalance(msg.sender, _parentID) > 0, "The caller does not have enough minting balance");

       // GenomicsDataManagement.UpdateSequencedNFTMintingBalance(msg.sender, _parentID); //The minting balance of msg.sender is decreased by 1
        tokenCount++;
        _safeMint(msg.sender, tokenCount); 
        _setTokenURI(tokenCount, _tokenURI);
        TradeManagement.LinkParentNFTtoChild1NFT(_parentID, tokenCount);
        TradeManagement.UpdateProducerMintingBalance(msg.sender, _parentID, 1);

        //GenomicsDataManagement.LinkChildNFTtoParentNFT(_parentID, tokenCount); //Calls the linkage function in the mgmt smart contract

        return(tokenCount);
    } 

        function mintAll(string[] memory _tokenURI, uint256 _parentID) external returns(uint) {
        require(TradeManagement.Producer(msg.sender) == true, "Only authorized producer can mint packaged product NFT");
        require(TradeManagement.ProducerRawMaterialMapping(_parentID) == msg.sender, "The specified parent ID does not belong to the caller");
        require(TradeManagement.ProducerPackagedProductsMintingBalance(msg.sender, _parentID) > 0, "The caller does not have enough minting balance");
        require(_tokenURI.length <= TradeManagement.ProducerPackagedProductsMintingBalance(msg.sender, _parentID), "Invalid number of URIs");

        for(uint256 i = 0; i <_tokenURI.length; i++){
            tokenCount++;
            _safeMint(msg.sender, tokenCount);
            _setTokenURI(tokenCount, _tokenURI[i]);
            TradeManagement.LinkParentNFTtoChild1NFT(_parentID, tokenCount);

        } 

        TradeManagement.UpdateProducerMintingBalance(msg.sender, _parentID, _tokenURI.length);
       
        
        return(tokenCount);
    } 

}
