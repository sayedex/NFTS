//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTCollectible is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    bytes32 public root;
    uint start;
    uint end;

    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 100;
    uint256 public  PRICE = 0.0000000000000001 ether;
    uint256 public  MAX_PER_MINT = 5;

    string public baseTokenURI;

    constructor(string memory baseURI,bytes32 _root) ERC721("NFT Collectible", "NFTC") {
        setBaseURI(baseURI);
        root = _root;
        start=block.timestamp;
    }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(10) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 10; i++) {
            _mintSingleNFT();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

//set when it will start

     modifier timeIsOver{
            require(block.timestamp>=end,"Time is up");
            _;
        }

  function endTimer(uint period) public onlyOwner {
            end=period+start;
        }
 function timeLeft() public view returns(uint){
            return end-block.timestamp;
        }



//only owner can call this function

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

//only owner can call this function

     function SetMaxmint(uint256 _newMax) public onlyOwner{
     MAX_PER_MINT = _newMax;
      }

//only owner can call this function
     function SetNewPrice(uint256 _PRICE) public onlyOwner{
       PRICE = _PRICE;
      }



    function mintNFTs(uint _count,bytes32[] calldata proof) public  payable timeIsOver{
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    //check is addresss is valid or not
  function isValid(bytes32[] calldata proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }


    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }



    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

}
