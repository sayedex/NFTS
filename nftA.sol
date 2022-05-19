pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract NFTCollectible is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    bytes32 public root;
    uint public end;
      //0xbe397a59186c9bf19dc618484690d99bfabf988ce2a5fc2e25ff5823d66bfa1b

    Counters.Counter private _tokenIds;

   //token info
  
    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }
   
  //allow token for minting 
    TokenInfo[] public AllowedCrypto;

    uint public constant MAX_SUPPLY = 100;
    uint256 public  PRICE = 0.0000000000000001 ether;
    uint256 public  MAX_PER_MINT = 5;

    string public baseTokenURI;

    constructor(string memory baseURI,bytes32 _root) ERC721("NFT Collectible", "NFTC") {
        setBaseURI(baseURI);
        root = _root;
      
    }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(10) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 10; i++) {
              uint newTokenID = _tokenIds.current();
             _safeMint(msg.sender, newTokenID);
             _tokenIds.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

//set when it will star
  function endTimer(uint period) public onlyOwner {
            end=period;
        }
//check countdown end or not
  function Countdown() public view returns (bool) {
 if(block.timestamp >=end){
return true;
 }else return false;

  }

//how much timeleft for starting NFT sale         
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

//add Token for minting...
 function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    function mintNFTs(uint _count,bytes32[] calldata proof,uint _pid) public  payable{
        require(Countdown(),"not started Yet");
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        //require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        if (msg.sender != owner()) {
            require(msg.value == cost * _count, "Not enough balance to complete transaction.");
            }

          for (uint256 i = 1; i <= _count; i++) {
                paytoken.transferFrom(msg.sender, address(this), cost);
                uint newTokenID = _tokenIds.current();
                _safeMint(msg.sender, newTokenID);
                 _tokenIds.increment();
            }
    }







    //check is addresss is valid or not
  function isValid(bytes32[] calldata proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
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


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
