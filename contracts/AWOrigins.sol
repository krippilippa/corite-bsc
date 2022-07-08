// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ICNR.sol";

contract AWOrigins is ERC721Enumerable, AccessControl {

    ICNR private CNR;

    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");

    uint256 public LAUNCH_MAX_SUPPLY;
    uint256 public LAUNCH_SUPPLY;
    uint256 public LAUNCHPAD_START_INDEX;
    address public LAUNCHPAD;

    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }

    constructor(ICNR _CNR, address _launchpad, uint256 _LPstartIndex, uint256 _LPmaxSupply, address _default_admin_role) ERC721("Corite x Alan Walker Origins", "Origins") {
        CNR = _CNR;
        LAUNCHPAD = _launchpad;
        LAUNCH_MAX_SUPPLY = _LPmaxSupply;
        LAUNCHPAD_START_INDEX = _LPstartIndex;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function mint(address _to, uint _tokenId) external onlyRole(MINTER){
        _mint(_to, _tokenId);
    }

    function mintTo(address to, uint size) external onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(LAUNCH_SUPPLY + size <= LAUNCH_MAX_SUPPLY, "max supply reached");

        for (uint256 i = 0; i < size; i++) {
            _mint(to, LAUNCHPAD_START_INDEX + LAUNCH_SUPPLY);
            LAUNCH_SUPPLY++;
        }
    }

    function burn(uint _tokenId) external onlyRole(BURNER){
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not owner nor approved");
        _burn(_tokenId);
    }

    function getMaxLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_MAX_SUPPLY;
    }

    function getLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_SUPPLY;
    }

    function setLaunchpad(address _launchpad) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LAUNCHPAD = _launchpad;
    }

    function tokenURI(uint _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return ICNR(CNR).getNFTURI(address(this), _tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
