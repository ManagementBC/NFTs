// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; //Imported in case burning NFTs is used
import "@openzeppelin/contracts/access/Ownable.sol";

    interface ITradeManagement{
        function Supplier(address) external view returns(bool);
    }

contract RawMaterials is ERC721URIStorage, Ownable{
    uint public tokenCount;
    ITradeManagement public TradeManagement;
    constructor () ERC721("RawMaterials", "RM"){

    } 

    function SetTradeManagementSC(address _trademgmtsc) external onlyOwner{
        TradeManagement = ITradeManagement(_trademgmtsc);
    }
    
    function mint(string memory _tokenURI) external returns(uint){
        require(TradeManagement.Supplier(msg.sender) == true, "Only authorized suppliers can mint packaged product NFT");

        tokenCount++;
        _safeMint(msg.sender, tokenCount); 
        _setTokenURI(tokenCount, _tokenURI);
        return(tokenCount);
    } 



}
