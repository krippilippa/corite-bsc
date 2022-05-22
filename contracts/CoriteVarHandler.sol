// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/ICoriteMNFT.sol";

contract CoriteVarHandler is AccessControl , Pausable{

    ICoriteMNFT public coriteMNFT;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    mapping (uint => uint) public groupCount;
    mapping (uint => uint) public groupRoof;
    mapping (uint => bool) public groupOpen;
    mapping (address => mapping (uint => bool)) hasMinted;

    event Group(uint group);

    constructor(ICoriteMNFT _coriteMNFT, address _default_admin_role) {
        coriteMNFT = _coriteMNFT;
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin_role);
    }

    function createGroup(uint _group, uint _nrInGroup) external onlyRole(ADMIN){
        require(_group > 999 && _group < 1100);
        groupCount[_group] = _group * 1_000_000;
        if (_nrInGroup == 0){
            groupRoof[_group] = 0;
        }else {
            groupRoof[_group] = groupCount[_group] + _nrInGroup;
        }
        groupOpen[_group] = true;
        emit Group(_group);
    }

    function setGroupStatus(uint _group, bool _open) external onlyRole(ADMIN){
        groupOpen[_group] = _open;
    }

    function claimNFT(uint _group) external whenNotPaused{
        require(groupOpen[_group] == true, "Minting for this group is closed");
        require(hasMinted[msg.sender][_group] == false, "This address has already minted an nft for this group");
        hasMinted[msg.sender][_group] = true;
        if(groupRoof[_group] == 0){
            _mint(msg.sender, _group);
        } else {
            require(groupCount[_group] < groupRoof[_group], "No more NFTs to mint in this group");
            _mint(msg.sender, _group);
        }
    }

    function mintForUser(address[] calldata _to, uint _group) external onlyRole(ADMIN){
        require(groupOpen[_group] == true, "Minting of group is closed");
        require(groupCount[_group] + _to.length <= groupRoof[_group], "Can not mint these many nfts");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _group);
        }
    }

    function mintBatch(address _to, uint _group, uint _nr) external onlyRole(ADMIN){
        require(groupOpen[_group], "Minting of group is closed");
        require(groupCount[_group] + _nr <= groupRoof[_group], "Can not mint these many nfts");
        for (uint256 i = 0; i < _nr; i++) {
            _mint(_to, _group);
        }
    }

    function _mint(address _to, uint _group) internal {
        groupCount[_group]++;
        coriteMNFT.mint(_to, groupCount[_group]);
    }

    function pauseHandler() public onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() public onlyRole(ADMIN) {
        _unpause();
    }
}
