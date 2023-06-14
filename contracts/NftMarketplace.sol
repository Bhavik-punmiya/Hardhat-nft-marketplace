// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; 

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract NftMarketplace {
        
    struct Listing{
        uint256 price;
        address seller;
    }
    
    error NftMarketplace__PriceMustBeAboveZero();
    error NftMarketplace__NotApprovedForTheMarketPlace();
    error NftMarketplace__AlreadyListed(address nftAddress, uint256 TokenId);
    error NftMarketplace__NotOwner();
    error NftMarketplace__NotListed();
    error NftMarketplace__PriceNotMet(address nftAddress, uint256 TokenId, uint256 price);
    error NftMarketplace__NoProceeds();
    error NftMarketplace__TransferFaild();


    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed TokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer, 
        address indexed nftAddress, 
        uint256 TokenId,uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 price
    );

     mapping(address => mapping(uint256 => Listing)) private s_Listings;
     mapping(address => uint256)  private s_proceeds;

    modifier  notListed (address nftAddress, uint256 TokenId){
        Listing memory listing = s_Listings[nftAddress][TokenId];
        if(listing.price > 0){
            revert NftMarketplace__AlreadyListed(nftAddress, TokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 TokenId){
        Listing memory  listing = s_Listings[nftAddress][TokenId];
        if(listing.price <= 0){
            revert NftMarketplace__NotListed();
        }
        _;
    }

    modifier isOwner(address nftAddress, uint256 TokenId, address sender){
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(TokenId);
        if(sender != owner){
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    function listItem(address nftAddress, uint256 TokenId, uint256 price) external notListed(nftAddress, TokenId) isOwner(nftAddress,TokenId, msg.sender) {
        if(price <= 0){
            revert NftMarketplace__PriceMustBeAboveZero();
        }
  
        IERC721 nft = IERC721(nftAddress);
        if(nft.getApproved(TokenId) != address(this)){
            revert NftMarketplace__NotApprovedForTheMarketPlace();
        }      

        s_Listings[nftAddress][TokenId] = Listing(price, msg.sender);

        emit ItemListed(msg.sender, nftAddress, TokenId, price);
      }

      function buyItem(address nftAddress, uint256 TokenId) external payable isListed(nftAddress, TokenId)  {
        Listing memory listedItem = s_Listings[nftAddress][TokenId];
        if(msg.value < listedItem.price){
            revert NftMarketplace__PriceNotMet(nftAddress, TokenId , listedItem.price);
        }
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        delete(s_Listings[nftAddress][TokenId]);
      
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, TokenId);
        emit ItemBought(msg.sender, nftAddress, TokenId, listedItem.price);
      }

      function cancelListing(address nftAddress, uint256 TokenId) external isOwner(nftAddress , TokenId, msg.sender) isListed(nftAddress, TokenId){
        delete (s_Listings[nftAddress][TokenId]);

        emit ItemCanceled(msg.sender, nftAddress, TokenId);
      }

      function updateListing(address nftAddress, uint256 TokenId, uint256 newPrice ) external isListed(nftAddress, TokenId) isOwner(nftAddress, TokenId, msg.sender){
       s_Listings[nftAddress][TokenId].price = newPrice;
       emit ItemListed(msg.sender, nftAddress, TokenId, newPrice);
      }

      function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if(proceeds<=0){
            revert NftMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
         (bool success, )= payable(msg.sender).call{value : proceeds}("");
        
        if(!success){
            revert NftMarketplace__TransferFaild();
        }

      }

      ///Getter Function 

      function getListing(address nftAddress , uint256 TokenId) external view returns (Listing memory){
        return s_Listings[nftAddress][TokenId];
      }

      function getProceeds(address seller) external view returns (uint256){
        return s_proceeds[seller];
      }
}