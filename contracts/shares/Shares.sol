// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WhitelistEnabledFor.sol";
import "../../interfaces/ICNR.sol";

contract Shares is Initializable, ERC721Upgradeable, WhitelistEnabledFor {
    bytes32 public constant MINT = keccak256("MINT");

    Whitelist public whitelistAddress;

    string private name_;
    string private symbol_;
    address private CNR;

    uint public supplyCap;
    uint public circulatingSupply;
    uint public burnCount;

    uint public firstPeriodStart;
    uint128 public periodLength;
    uint128 public flushDelay;

    bool public adminForceBackDisabled;
    bool public burnEnabled;

    mapping(address => uint) public retroactiveTotals;
    mapping(address => ClaimPeriod[]) public tokenPeriods;

    struct ClaimPeriod {
        uint start;
        uint startCap;
        uint startMaxTokenId;
        uint128 shareEarnings;
        uint128 earningsAccountedFor;
        mapping(uint => uint) claimedPerShare;
    }

    event IssuanceOfShares(uint sharesInCirculation, uint oldCap, uint newCap);
    event IssuerMintOfShares(uint IDfrom, uint IDto);
    event EarningsClaimed(
        address indexed user,
        address indexed token,
        uint totalAmount,
        uint[] shareIds,
        uint periodIndex,
        uint maxShareEarnings
    );
    event Flush(address indexed token, uint periodIndex);
    event ForceBackShares(uint[] shareIds);
    event ChangeNameAndSymbol(
        string oldName,
        string oldSymbol,
        string newName,
        string newSymbol
    );
    event CalculateTokenDistribution(
        address indexed token,
        uint indexed periodIndex,
        uint newShareEarnings
    );
    event ChangeWhitelist(Whitelist old, Whitelist _new);
    event BurnEnabled(bool enabled);
    event DisableAdminForceback();

    function initialize(
        string memory _collectionName,
        string memory _collectionSymbol,
        address _CNR,
        address _default_admin
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);
        _setupRole(ADMIN, _default_admin);
        __ERC721_init(_collectionName, _collectionSymbol);
        name_ = _collectionName;
        symbol_ = _collectionSymbol;
        CNR = _CNR;
        whitelistAddress = this;
        periodLength = 365 days;
        flushDelay = 90 days;
    }

    receive() external payable {}

    function issuanceOfShares(uint _nrToIssue) external onlyRole(ADMIN) {
        require(
            supplyCap == circulatingSupply,
            "Can not issue more shares before minting existing ones"
        );
        require(_nrToIssue > 0, "Can not issue zero shares");

        if (supplyCap == 0) {
            firstPeriodStart = block.timestamp;
        }
        supplyCap += _nrToIssue;
        emit IssuanceOfShares(
            circulatingSupply,
            supplyCap - _nrToIssue,
            supplyCap
        );
    }

    function calculateTokensDistribution(address[] calldata _tokens) external {
        for (uint256 index = 0; index < _tokens.length; index++) {
            calculateTokenDistribution(_tokens[index]);
        }
    }

    function calculateTokenDistribution(address _token) public {
        require(supplyCap != 0, "Must issue shares");
        ClaimPeriod[] storage claimPeriods = tokenPeriods[_token];
        if (claimPeriods.length == 0) {
            claimPeriods.push();
            ClaimPeriod storage period = claimPeriods[0];
            period.start = firstPeriodStart;
            period.startCap = supplyCap;
            period.startMaxTokenId = supplyCap + burnCount;
        }

        uint activePeriodIndex = claimPeriods.length - 1;
        ClaimPeriod storage activePeriod = claimPeriods[activePeriodIndex];

        if (block.timestamp < activePeriod.start + periodLength) {
            _distribution(activePeriod, activePeriodIndex, _token);
        } else {
            claimPeriods.push();
            ClaimPeriod storage nextPeriod = claimPeriods[
                activePeriodIndex + 1
            ];
            nextPeriod.startCap = supplyCap;
            nextPeriod.startMaxTokenId = supplyCap + burnCount;
            nextPeriod.start =
                activePeriod.start +
                (((block.timestamp - activePeriod.start) / periodLength) *
                    periodLength);
            retroactiveTotals[_token] += activePeriod.earningsAccountedFor;
            _distribution(nextPeriod, activePeriodIndex + 1, _token);
        }
    }

    function _distribution(
        ClaimPeriod storage _period,
        uint _periodIndex,
        address _token
    ) internal {
        uint balance;
        if (_token == address(0)) {
            balance = address(this).balance - retroactiveTotals[address(0)];
        } else {
            balance =
                IERC20(_token).balanceOf(address(this)) -
                retroactiveTotals[_token];
        }
        _period.shareEarnings += uint128(
            (balance - _period.earningsAccountedFor) / _period.startCap
        );
        _period.earningsAccountedFor = uint128(balance);
        emit CalculateTokenDistribution(
            _token,
            _periodIndex,
            _period.shareEarnings
        );
    }

    function mint(address _to, uint _quantity) public onlyRole(MINT) {
        uint target = circulatingSupply + _quantity;
        require(target <= supplyCap, "Cap overflow");
        uint idTarget = target + burnCount;
        for (
            uint256 index = circulatingSupply + burnCount + 1;
            index <= idTarget;
            index++
        ) {
            _safeMint(_to, index);
        }
        emit IssuerMintOfShares(circulatingSupply, target);
        circulatingSupply = target;
    }

    function burnBatch(uint[] calldata _tokens) external {
        require(burnEnabled, "Burning shares is disabled");
        uint tokenAmount = _tokens.length;
        circulatingSupply -= tokenAmount;
        supplyCap -= tokenAmount;
        burnCount += tokenAmount;
        for (uint i = 0; i < tokenAmount; i++) {
            require(
                _isApprovedOrOwner(msg.sender, _tokens[i]),
                "Invalid token owner"
            );
            _burn(_tokens[i]);
        }
    }

    function setBurnEnabled(bool _enabled) external onlyRole(ADMIN) {
        burnEnabled = _enabled;
        emit BurnEnabled(_enabled);
    }

    function claimEarnings(
        address _token,
        uint _claimPeriod,
        address _owner,
        uint[] calldata _shareIds
    ) external {
        uint totalToGet = _totalToGet(_token, _claimPeriod, _owner, _shareIds);
        IERC20(_token).transfer(_owner, totalToGet);
        emit EarningsClaimed(
            _owner,
            _token,
            totalToGet,
            _shareIds,
            _claimPeriod,
            tokenPeriods[_token][_claimPeriod].shareEarnings
        );
    }

    function claimEarningsNative(
        uint _claimPeriod,
        address _owner,
        uint[] calldata _shareIds
    ) external {
        uint totalToGet = _totalToGet(
            address(0),
            _claimPeriod,
            _owner,
            _shareIds
        );
        (bool sent, ) = _owner.call{value: totalToGet}("");
        require(sent, "Failed to transfer native token");
        emit EarningsClaimed(
            _owner,
            address(0),
            totalToGet,
            _shareIds,
            _claimPeriod,
            tokenPeriods[address(0)][_claimPeriod].shareEarnings
        );
    }

    function _totalToGet(
        address _token,
        uint _periodIndex,
        address _owner,
        uint[] calldata _shareIds
    ) internal returns (uint totalToGet) {
        ClaimPeriod storage period = tokenPeriods[_token][_periodIndex];
        if (claimWhiteListRequired) {
            require(
                whitelistAddress.whitelist(_owner),
                "Address not whitelisted"
            );
        }
        require(
            period.earningsAccountedFor != 0,
            "Nothing to claim or flushed"
        );
        uint target = period.shareEarnings;

        uint startMaxTokenId = period.startMaxTokenId + 1;
        for (uint256 index = 0; index < _shareIds.length; index++) {
            uint share = _shareIds[index];
            if (share < startMaxTokenId) {
                require(ownerOf(share) == _owner, "Not owner of share");
                totalToGet += target - period.claimedPerShare[share];
                period.claimedPerShare[share] = target;
            }
        }
        require(totalToGet > 0, "Nothing to claim");
        if (_periodIndex < tokenPeriods[_token].length - 1) {
            retroactiveTotals[_token] -= totalToGet;
        }
        period.earningsAccountedFor -= uint128(totalToGet);
    }

    function flush(
        uint _periodIndex,
        address[] calldata _tokens
    ) external onlyRole(ADMIN) {
        for (uint256 index = 0; index < _tokens.length; index++) {
            _flush(_periodIndex, _tokens[index]);
        }
    }

    function _flush(uint _periodIndex, address _token) internal {
        ClaimPeriod storage period = tokenPeriods[_token][_periodIndex];
        require(
            block.timestamp > period.start + periodLength + flushDelay,
            "Not Possible to flush this period yet"
        );
        if (_periodIndex < tokenPeriods[_token].length - 1) {
            retroactiveTotals[_token] -= period.earningsAccountedFor;
        }
        if (_token == address(0)) {
            uint toSend = period.earningsAccountedFor; // prevent reentrancy
            period.earningsAccountedFor = 0;
            (bool sent, ) = msg.sender.call{value: toSend}("");
            require(sent, "Failed to transfer native token");
        } else {
            IERC20(_token).transfer(msg.sender, period.earningsAccountedFor);
            period.earningsAccountedFor = 0;
        }
        emit Flush(_token, _periodIndex);
    }

    function setPeriodAndDelay(
        uint128 _periodLength,
        uint128 _flushDelay
    ) external onlyRole(ADMIN) {
        require(supplyCap == 0, "Contract already started");
        periodLength = _periodLength;
        flushDelay = _flushDelay;
    }

    function setFirstPeriodStart(uint _startTime) external onlyRole(ADMIN) {
        require(supplyCap == 0, "Contract already started");
        require(
            _startTime <= block.timestamp,
            "Can not start period in the future"
        );
        firstPeriodStart = _startTime;
    }

    function adminForceBackShares(
        uint[] calldata _ids,
        address _to
    ) external onlyRole(ADMIN) {
        require(!adminForceBackDisabled, "Force back has been disabled");
        for (uint256 index = 0; index < _ids.length; index++) {
            _transfer(ownerOf(_ids[index]), _to, _ids[index]);
        }
        emit ForceBackShares(_ids);
    }

    function disableAdminForceBack() external onlyRole(ADMIN) {
        adminForceBackDisabled = true;
        emit DisableAdminForceback();
    }

    function setNameAndSymbol(
        string memory _newName,
        string memory _newSymbol
    ) external onlyRole(ADMIN) {
        emit ChangeNameAndSymbol(name_, symbol_, _newName, _newSymbol);
        name_ = _newName;
        symbol_ = _newSymbol;
    }

    function setWhitelistAddress(
        Whitelist _wlAddress
    ) external onlyRole(ADMIN) {
        emit ChangeWhitelist(whitelistAddress, _wlAddress);
        whitelistAddress = _wlAddress;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function name() public view override returns (string memory) {
        return name_;
    }

    function symbol() public view override returns (string memory) {
        return symbol_;
    }

    function getLeftToClaim(
        address _token,
        uint _claimPeriod,
        uint[] calldata _shareIds
    ) external view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](_shareIds.length);
        uint maxClaim = tokenPeriods[_token][_claimPeriod].shareEarnings;
        for (uint i = 0; i < _shareIds.length; i++) {
            arr[i] =
                maxClaim -
                tokenPeriods[_token][_claimPeriod].claimedPerShare[
                    _shareIds[i]
                ];
        }
        return arr;
    }

    function getFlushableAmount(
        address _token,
        uint _claimPeriod
    ) external view returns (uint256 amount) {
        ClaimPeriod storage period = tokenPeriods[_token][_claimPeriod];
        require(
            block.timestamp > period.start + periodLength + flushDelay,
            "Not Possible to flush this period yet"
        );
        return period.earningsAccountedFor;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (!(from == address(0) || hasRole(ADMIN, msg.sender))) {
            require(!transferBlocked, "Transfers are currently blocked");
            if (transferWhiteListRequired) {
                require(
                    whitelistAddress.whitelist(from) &&
                        whitelistAddress.whitelist(to),
                    "Invalid token transfer"
                );
            }
        }
    }

    function tokenURI(
        uint _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return ICNR(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;
}
