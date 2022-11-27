// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

    interface ILot{
        function mint(string memory, uint256[5] memory, address) external;
    }

contract TradeManagement is ReentrancyGuard{

    //** General Variables **//

    IERC721 public RawMaterialsSmartContract; 
    IERC721 public PackagedProductsSmartContract;
    IERC721 public LotSmartContract;
    ILot public Lot;
    address public FoodAuthority; 
    uint256 public RawMaterialsCount;
    uint256 public PackagedProductCount;
    uint256 public LotCount; 
    mapping(address => bool) public Supplier;
    mapping(address => bool) public Producer;
    mapping(address => bool) public Retailer;

    struct RawMaterialNFT{
        uint256 RawMaterialID;
        IERC721 nftSC; 
        uint256 tokenID; 
        address payable RawMaterialOwner;
    }


    struct PackagedProductNFT{
        uint256 PackagedProductID;
        IERC721 nftSC;
        uint256 tokenID;
        address payable PackagedProductOwner;
    }

    struct LotNFT{
        uint256 LotID;
        IERC721 nftSC;
        uint256 tokenID;
        address payable LotOwner;
    }




    //RawMaterialsCount => RawMaterialNFTStruct
    mapping(uint256 => RawMaterialNFT) public RawMaterialsMapping;


    //PackagedProductCount => PackagedProductNFTStruct
    mapping(uint256 => PackagedProductNFT) public PackagedProductsMapping;

    //LotCount => LotNFT Struct
    mapping(uint256 => LotNFT) public LotMapping; //This one is for producer

    //LotCount => LotNFT Struct
    mapping(uint256 => LotNFT) public LotMapping2; //This one is for retailer 

    
    //** Raw Materials Auction Variables **//

    //RawmaterialTokenID => End time
    mapping(uint256 => uint256) public RawMaterialAuctionEndTime;
    //RawMaterialTokenID => bool
    mapping(uint256 => bool) public RawMaterialAuctionStarted;
    //RawMaterialTokenID => bool
    mapping(uint256 => bool) public RawMaterialAuctionEnded;
    //RawMaterialTokenID => (RawMaterialBidders => bids)
    mapping(uint256 => mapping(address => uint256)) public RawMaterialAuctionPendingBids;
    //RawMaterialTokenID => highest bid
    mapping(uint256 => uint256) public RawMaterialAuctionHighestBid;
    //RawMaterialTokenID => Highest Bidder
    mapping(uint256 => address) public RawMaterialAuctionHighestBidder;

    
    //** Packaged Products Production Variables **//

    // RawMaterialTokenID => Producer address
    mapping(uint256 => address) public ProducerRawMaterialMapping;

    // ProducerAddress => (TokenID => PackagedProductsMintingBalance)
    mapping(address => mapping(uint256 => uint256)) public ProducerPackagedProductsMintingBalance; 

    // NewProductNFT => Parent RawMaterialNFT
    //mapping(uint256 => uint256) public ProductNFTRawMaterialNFTMapping; 



    //** Lot Creation Variables **//

    // Producer address => Lot minting balance
    //mapping(address => uint256) public ProducerLotMintingBalance;

    //Lot number => Producer address 
    mapping(uint256 => address) public ProducerLotMapping;

    //** Lot Auction Variables **//

    //LotTokenID => End time
    mapping(uint256 => uint256) public LotAuctionEndTime;
    //LotTokenID => bool
    mapping(uint256 => bool) public LotAuctionStarted;
    //LotTokenID => bool
    mapping(uint256 => bool) public LotAuctionEnded;
    //LotTokenID => (LotBidders => bids)
    mapping(uint256 => mapping(address => uint256)) public LotAuctionPendingBids;
    //LotTokenID => highest bid
    mapping(uint256 => uint256) public LotAuctionHighestBid;
    //LotTokenID => Highest Bidder
    mapping(uint256 => address) public LotAuctionHighestBidder;

    //** Products Auction Variables **//

    //ProductTokenID => End time
    mapping(uint256 => uint256) public ProductAuctionEndTime;
    //ProductTokenID => bool
    mapping(uint256 => bool) public ProductAuctionStarted;
    //ProductTokenID => bool
    mapping(uint256 => bool) public ProductAuctionEnded;
    //ProductTokenID => (LotBidders => bids)
    mapping(uint256 => mapping(address => uint256)) public ProductAuctionPendingBids;
    //ProductTokenID => highest bid
    mapping(uint256 => uint256) public ProductAuctionHighestBid;
    //ProductTokenID => Highest Bidder
    mapping(uint256 => address) public ProductAuctionHighestBidder;











    //** NFT Composability Mappings **//

    //RawMaterialsSmartContract => PackagedProductsSmartContract
    mapping(address => address) public parentToChildAddress1; //Maps the smart contract of  RawMaterials (child) to packagedproducts (Parent)

    //RawMaterialsTokenID (deposited by producer) => PackagedProductsTokenID 
    mapping(uint256 => uint256[5]) public parentToChildTokenId1;

    //RawMaterialsTokenID => positioncounter
    mapping(uint256 => uint256) public parentToChild1positioncounter;

    //parentID => (childID => bool)
    //mapping(uint256 => mapping(uint256 => bool)) public parentToChildTokenId1;

    //LotTokenID => PackagedProductsTokenIDs
    mapping(uint256 => uint256[5]) public parentToChildTokenId2;

    //** Events **//
    event RawMaterialNFTAuctionStarted(uint256 tokencount, address contractaddress, uint256 tokenID, uint256 RawMaterialAuctionEndTime, address NFTOwner);
    event RawMaterialNFTDelisted(uint256 tokencount, address contractaddress, uint256 tokenID , address NFTOwner);
    event RawMaterialNFTPlacedBid (uint256 tokencount, address highestbidder, uint256 highestbid);
    event RawMaterialNFTAuctionEnded(uint256 tokencount, address highestbidder, uint256 highestbid);
    event LotNFTAuctionStarted(uint256 tokencount, address contractaddress, uint256 tokenID, uint256 auctionendtime, address NFTOwner);
    event LotNFTPlacedBid(uint256 tokencount, address highestbidder, uint256 highestbid);
    event LotNFTAuctionEnded(uint256 tokencount, address highestbidder, uint256 highestbid);
    event PackagedProductNFTAuctionStarted(uint256 tokencount, address contractaddress, uint256 tokenID, uint256 auctionendtime, address NFTOwner);
    event PackagedProductNFTPlacedBid(uint256 tokencount, address highestbidder, uint256 highestbid);
    event PackagedProductNFTAuctionEnded(uint256 tokencount, address highestbidder, uint256 highestbid);







    constructor(address _rawmaterialsaddress, address _packagedproductsaddress, address _Lotaddress){
        RawMaterialsSmartContract = IERC721(_rawmaterialsaddress);
        PackagedProductsSmartContract = IERC721(_packagedproductsaddress);
        LotSmartContract = IERC721(_Lotaddress);
        Lot = ILot(_Lotaddress);
        FoodAuthority = msg.sender;
    }



    //** Modifiers **//
    modifier onlyFoodAuthority{
        require(msg.sender == FoodAuthority, "Only the food authority can run this function");
        _;
    }

    modifier onlySupplier{
        require(Supplier[msg.sender], "Only authorized suppliers are allowed to run this function");
        _;
    }

    modifier onlyProducer{
        require(Producer[msg.sender], "Only authorized producers are allowed to run this function");
        _;
    }

    modifier onlyRetailer{
        require(Retailer[msg.sender], "Only authorized retailers are allowed to run this function");
        _;
    }

    modifier onlyPackagedProductsSmartContract{
        require(msg.sender == address(PackagedProductsSmartContract), "Only the packaged products smart contract can run this function");
        _;
    }

    modifier onlyLotSmartContract{
        require(msg.sender == address(LotSmartContract), "Only the Lot smart contract can run this function");
        _;
    }

    //** Functions **//

    function RegisterProducer(address _producer) external onlyFoodAuthority{
        Producer[_producer] = true;
    }

    function RegisterSupplier(address _supplier) external onlyFoodAuthority{
        Supplier[_supplier] = true;
    }

    function RegisterRetailer(address _retailer) external onlyFoodAuthority{
        Retailer[_retailer] = true;
    }




    function ListRawMaterialNFT(uint256 _tokenID, uint256 _endTime, uint256 _startingBid) external nonReentrant onlySupplier{
        require(_endTime > 0, "The auction end time must be greater than 0");
        RawMaterialsSmartContract.transferFrom(msg.sender, address(this), _tokenID);
        RawMaterialsCount++; 
        RawMaterialsMapping[RawMaterialsCount] = RawMaterialNFT(RawMaterialsCount, RawMaterialsSmartContract, _tokenID, payable(msg.sender));

        RawMaterialAuctionEndTime[RawMaterialsCount] = block.timestamp + (_endTime * 1 seconds);
        RawMaterialAuctionStarted[RawMaterialsCount] = true;
        RawMaterialAuctionHighestBid[RawMaterialsCount] = _startingBid * 1 ether; //This specifies the starting bid for this NFT
        

        emit RawMaterialNFTAuctionStarted(RawMaterialsCount, address(RawMaterialsSmartContract), _tokenID, RawMaterialAuctionEndTime[RawMaterialsCount], msg.sender);
    }

    function RawMaterialNFTPlaceBid(uint256 _RawMaterialsCount) external payable nonReentrant onlyProducer{
        RawMaterialNFT storage RawMaterial = RawMaterialsMapping[_RawMaterialsCount];
        require(_RawMaterialsCount > 0 && _RawMaterialsCount <= RawMaterialsCount, "The entered Rawmaterial number is invalid");
        require(RawMaterialAuctionStarted[RawMaterial.RawMaterialID], "There is no active auction for this NFT");
        require(block.timestamp < RawMaterialAuctionEndTime[RawMaterial.RawMaterialID], "The auction for this NFT has already closed");
        require(msg.value > RawMaterialAuctionHighestBid[RawMaterial.RawMaterialID], "The placed bid is not higher than the existing highest bid");

        if(RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID] != address(0)){
            RawMaterialAuctionPendingBids[RawMaterial.RawMaterialID][RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID]] = RawMaterialAuctionHighestBid[RawMaterial.RawMaterialID];
        }

        RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID] = msg.sender;
        RawMaterialAuctionHighestBid[RawMaterial.RawMaterialID] = msg.value;

        emit RawMaterialNFTPlacedBid (RawMaterial.RawMaterialID, msg.sender, msg.value);
    }

    function RawMaterialNFTWithdrawBid(uint256 _RawMaterialsCount) external nonReentrant{
        uint256 balance = RawMaterialAuctionPendingBids[_RawMaterialsCount][msg.sender];
        RawMaterialAuctionPendingBids[_RawMaterialsCount][msg.sender] = 0;

        payable(msg.sender).transfer(balance);

        //Can add event
    }

    function RawMaterialNFTEndAuction(uint256 _RawMaterialsCount) external nonReentrant{
        RawMaterialNFT storage RawMaterial = RawMaterialsMapping[_RawMaterialsCount];
        require(RawMaterialAuctionStarted[RawMaterial.RawMaterialID], "There is no active auction for this NFT");
        require(block.timestamp >= RawMaterialAuctionEndTime[RawMaterial.RawMaterialID], "The auction for this NFT has not closed yet");
        require(!RawMaterialAuctionEnded[RawMaterial.RawMaterialID], "The auction for this NFT has already been ended");

        RawMaterialAuctionEnded[RawMaterial.RawMaterialID] = true;

        if(RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID] != address(0)){
            RawMaterialsSmartContract.safeTransferFrom(address(this),RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID], RawMaterial.tokenID);
            RawMaterial.RawMaterialOwner.transfer(RawMaterialAuctionHighestBid[RawMaterial.RawMaterialID]);
            emit RawMaterialNFTAuctionEnded(RawMaterial.RawMaterialID, RawMaterialAuctionHighestBidder[RawMaterial.RawMaterialID], RawMaterialAuctionHighestBid[RawMaterial.RawMaterialID]);
            delete RawMaterialsMapping[_RawMaterialsCount];

        } else {
            RawMaterialsSmartContract.safeTransferFrom(address(this),RawMaterial.RawMaterialOwner, RawMaterial.tokenID);
            delete RawMaterialsMapping[_RawMaterialsCount];
        }
    }

    //Minting can be done like the lot creation function
    function ProducePackagedProducts(uint256 _tokenID) external nonReentrant onlyProducer{

        RawMaterialsSmartContract.transferFrom(msg.sender, address(this), _tokenID);
        ProducerRawMaterialMapping[_tokenID] = msg.sender;
        ProducerPackagedProductsMintingBalance[msg.sender][_tokenID] = 5;

    }

    function UpdateProducerMintingBalance(address _producer, uint256 _tokenID, uint256 _numberofmints) external onlyPackagedProductsSmartContract{

        ProducerPackagedProductsMintingBalance[_producer][_tokenID] -= _numberofmints;
    }

        function LinkParentNFTtoChild1NFT (uint256 _childID, uint256 _parentID) external onlyPackagedProductsSmartContract{
        require(parentToChild1positioncounter[_childID] <= 5, "Cannot add more parent NFTs to this child NFT because the max capacity is reached");

        parentToChildTokenId1[_childID][parentToChild1positioncounter[_childID]] = _parentID ; //IF mapping instead of array ==>  parentToChildTokenId1[RawMaterial.tokenID][_childID] = true;

        parentToChild1positioncounter[_childID] += 1;    
    }

    function CreateLot(uint256[5] memory _tokenIDs, string memory _tokenURI) external onlyProducer{
        for(uint256 i = 0; i < _tokenIDs.length; i++){
            require(PackagedProductsSmartContract.ownerOf(_tokenIDs[i]) == msg.sender,"The token ID does not belong to the caller");
        }

        for(uint256 i = 0; i < _tokenIDs.length; i++){
            PackagedProductsSmartContract.transferFrom(msg.sender, address(this), _tokenIDs[i]);
        }

        Lot.mint(_tokenURI,_tokenIDs, msg.sender);

    }

    function LinkParentNFTtoChild2NFT(uint256 _parentID, uint256[5] memory _childIDs) external onlyLotSmartContract{

        for(uint256 i = 0; i < _childIDs.length; i++ ){
            parentToChildTokenId2[_parentID][i] = _childIDs[i];
        }

    }

    function ListLotNFT(uint256 _tokenID, uint256 _endTime, uint256 _startingBid) external nonReentrant onlyProducer{
        require(_endTime > 0, "The auction end time must be greater than zero");
        LotSmartContract.transferFrom(msg.sender, address(this), _tokenID);
        LotCount++;
        LotMapping[LotCount] = LotNFT(LotCount, LotSmartContract, _tokenID, payable(msg.sender));

        LotAuctionEndTime[LotCount] = block.timestamp + (_endTime * 1 seconds);
        LotAuctionStarted[LotCount] = true;
        LotAuctionHighestBid[LotCount] = _startingBid * 1 ether;

        emit LotNFTAuctionStarted(LotCount, address(LotSmartContract), _tokenID, LotAuctionEndTime[LotCount], msg.sender);

    }

    function LotNFTPlaceBid(uint256 _LotCount) external payable nonReentrant onlyRetailer{
        LotNFT storage Lots = LotMapping[_LotCount];
        require(_LotCount > 0 && _LotCount <= LotCount, "The entered Lot number is invalid");
        require(LotAuctionStarted[Lots.LotID], "There is no active auction for this NFT");
        require(block.timestamp < LotAuctionEndTime[Lots.LotID], "The auction for this NFT has already closed");
        require(msg.value > LotAuctionHighestBid[Lots.LotID], "The placed bid is not higher than the existing highest bid");

        if(LotAuctionHighestBidder[Lots.LotID] != address(0)){
            LotAuctionPendingBids[Lots.LotID][LotAuctionHighestBidder[Lots.LotID]] = LotAuctionHighestBid[Lots.LotID];
        }


        LotAuctionHighestBidder[Lots.LotID] = msg.sender;
        LotAuctionHighestBid[Lots.LotID] = msg.value;

        emit LotNFTPlacedBid(Lots.LotID, msg.sender, msg.value);
    }

    function LotNFTWithdrawBid(uint256 _LotCount) external nonReentrant{
        uint256 balance = LotAuctionPendingBids[_LotCount][msg.sender];
        LotAuctionPendingBids[_LotCount][msg.sender] = 0;

        payable(msg.sender).transfer(balance);
    }

    function LotNFTEndAuction(uint256 _LotCount) external nonReentrant{
        LotNFT storage Lots = LotMapping[_LotCount];
        require(LotAuctionStarted[Lots.LotID], "There is no active auction for this NFT");
        require(block.timestamp >= LotAuctionEndTime[Lots.LotID], "The auction for this NFT has not closed yet");
        require(!LotAuctionEnded[Lots.LotID], "The auction for this NFT has already been ended");

        LotAuctionEnded[Lots.LotID] = true;

        if(LotAuctionHighestBidder[Lots.LotID] != address(0)){
            LotSmartContract.safeTransferFrom(address(this),LotAuctionHighestBidder[Lots.LotID], Lots.tokenID);
            Lots.LotOwner.transfer(LotAuctionHighestBid[Lots.LotID]);
            //delete LotMapping[Lots.LotID];
            emit LotNFTAuctionEnded(Lots.LotID, LotAuctionHighestBidder[Lots.LotID], LotAuctionHighestBid[Lots.LotID]);

        } else {
            LotSmartContract.safeTransferFrom(address(this),Lots.LotOwner, Lots.tokenID);
            delete LotMapping[Lots.LotID];
        }
    }

    function RedeemPackagedProducts(uint256 _LotCount) external nonReentrant onlyRetailer{
        LotNFT storage Lots = LotMapping[_LotCount];

        LotSmartContract.transferFrom(msg.sender, address(this), Lots.tokenID);

        for(uint256 i = 0; i < parentToChildTokenId2[Lots.LotID].length; i++ ){
            PackagedProductsSmartContract.safeTransferFrom(address(this), msg.sender, parentToChildTokenId2[Lots.LotID][i]);
        }
    }

    function ListProductNFT(uint256 _tokenID, uint256 _endTime, uint256 _startingBid) external nonReentrant onlyRetailer{
        require(_endTime > 0, "The auction end time must be greater than zero");
        PackagedProductsSmartContract.transferFrom(msg.sender, address(this), _tokenID);
        PackagedProductCount++;
        PackagedProductsMapping[PackagedProductCount] = PackagedProductNFT(PackagedProductCount, PackagedProductsSmartContract, _tokenID, payable(msg.sender));

        ProductAuctionEndTime[PackagedProductCount] = block.timestamp + (_endTime * 1 seconds);
        ProductAuctionStarted[PackagedProductCount] = true;
        ProductAuctionHighestBid[PackagedProductCount] = _startingBid * 1 ether;

        emit PackagedProductNFTAuctionStarted(PackagedProductCount, address(PackagedProductsSmartContract), _tokenID, ProductAuctionEndTime[PackagedProductCount], msg.sender);
    } 

    function ProductNFTPlaceBid(uint256 _PackagedProductCount) external payable nonReentrant{
        PackagedProductNFT storage PP = PackagedProductsMapping[_PackagedProductCount];
        require(_PackagedProductCount > 0 && _PackagedProductCount <= PackagedProductCount, "The entered Lot number is invalid");
        require(ProductAuctionStarted[PP.PackagedProductID], "There is no active auction for this NFT");
        require(block.timestamp < ProductAuctionEndTime[PP.PackagedProductID], "The auction for this NFT has already closed");
        require(msg.value > ProductAuctionHighestBid[PP.PackagedProductID], "The placed bid is not higher than the existing highest bid");

        if(ProductAuctionHighestBidder[PP.PackagedProductID] != address(0)){
            ProductAuctionPendingBids[PP.PackagedProductID][ProductAuctionHighestBidder[PP.PackagedProductID]] = ProductAuctionHighestBid[PP.PackagedProductID];
        }

        ProductAuctionHighestBidder[PP.PackagedProductID] = msg.sender;
        ProductAuctionHighestBid[PP.PackagedProductID] = msg.value;

        emit PackagedProductNFTPlacedBid(PP.PackagedProductID, msg.sender, msg.value);
    }

    function ProductNFTWithdrawBid(uint256 _PackagedProductCount) external nonReentrant{
        uint256 balance = ProductAuctionPendingBids[_PackagedProductCount][msg.sender];
        ProductAuctionPendingBids[_PackagedProductCount][msg.sender] = 0;

        payable(msg.sender).transfer(balance);
    }

    function ProductNFTEndAuction(uint256 _PackagedProductCount) external nonReentrant{
        PackagedProductNFT storage PP = PackagedProductsMapping[_PackagedProductCount];
        require(ProductAuctionStarted[PP.PackagedProductID], "There is no active auction for this NFT");
        require(block.timestamp >= ProductAuctionEndTime[PP.PackagedProductID], "The auction for this NFT has not closed yet");
        require(!ProductAuctionEnded[PP.PackagedProductID], "The auction for this NFT has already been ended");

        ProductAuctionEnded[PP.PackagedProductID] = true;

        if(ProductAuctionHighestBidder[PP.PackagedProductID] != address(0)){
            PackagedProductsSmartContract.safeTransferFrom(address(this),ProductAuctionHighestBidder[PP.PackagedProductID], PP.tokenID);
            PP.PackagedProductOwner.transfer(ProductAuctionHighestBid[PP.PackagedProductID]);
            emit PackagedProductNFTAuctionEnded(PP.PackagedProductID, ProductAuctionHighestBidder[PP.PackagedProductID], ProductAuctionHighestBid[PP.PackagedProductID]);
            delete PackagedProductsMapping[PP.PackagedProductID];

        } else {
            PackagedProductsSmartContract.safeTransferFrom(address(this),PP.PackagedProductOwner, PP.tokenID);
            delete PackagedProductsMapping[PP.PackagedProductID];
        }
    }  

}
