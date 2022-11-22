// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; //Imported in case burning NFTs is used
import "@openzeppelin/contracts/access/Ownable.sol";



    interface ITradeManagement{
        function LinkParentNFTtoChild2NFT(uint256, uint256[4] memory) external;
    }

contract Lot is ERC721URIStorage, Ownable{
    uint public tokenCount;
    ITradeManagement public TradeManagement;
    constructor () ERC721("Lot", "LOT"){

    } 

        modifier onlyTradeManagementSmartContract{
        require(msg.sender == address(TradeManagement), "Only the Trade Management smart contract can run this function");
        _;
    }
 


    function SetTradeManagementSC(address _trademgmtsc) external onlyOwner{
        TradeManagement = ITradeManagement(_trademgmtsc);
    }

    function mint(string memory _tokenURI, uint256[4] memory _childIDs, address _LotCreator) external onlyTradeManagementSmartContract returns(uint) {
        tokenCount++;
        _safeMint(_LotCreator, tokenCount); 
        _setTokenURI(tokenCount, _tokenURI);
        TradeManagement.LinkParentNFTtoChild2NFT(tokenCount, _childIDs);

        //GenomicsDataManagement.LinkChildNFTtoParentNFT(_parentID, tokenCount); //Calls the linkage function in the mgmt smart contract

        return(tokenCount);
    } 


}
