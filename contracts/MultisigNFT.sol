//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MultisigNFT
 * @dev description: create NFT's that are owned by several addresses, or co-signers
 * @dev co-signers can create and vote on proposals in order to make various kinds of decisions
 * @dev these decisions could be anything from adding/removing co-signers, making investments in crypto/nft projects,
 *      sending eth to other contracts or calling their public functions
 */

contract MultisigNFT is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev contract state variables
     */
    string private _name;
    string private _symbol;
    uint256 private _tokenId;
    uint256 private _proposalId;
    uint256 private _proposalCount;

    /**
     * @dev Proposal struct
     * @param proposer the address of the proposal creator
     * @param tokenId the token ID that the proposal is targeting
     * @param action the action being voted on
     * @param isApproved approval status of the proposal
     */
    struct Proposal {
        address proposer;
        uint256 tokenId;
        uint32 action;
        string[] params;
        bool isApproved;
    }

    /**
     * @dev Mappings
     * @notice _coSigners - tokenId => co-signer
     * @notice _owners - tokenId => token owner
     * @notice _isCoSigner - token ID => is co-signer?
     * @notice _isOwner - token ID => is owner?
     * @notice _balances - owner address => token count
     * @notice _tokenApprovals - tokenId => approved address
     * @notice _proposals - proposalId => Proposal
     * @notice _votes - proposal ID => [coSigners => vote]
     * @notice _requiredSignatures - tokenId => required signatures
     * @notice _operatorApprovals
     */
    mapping(uint256 => address[]) private _coSigners;
    mapping(uint256 => address) private _owners;
    mapping(address => bool) private _isCoSigner;
    mapping(address => bool) private _isOwner;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _votes;
    mapping(uint256 => uint8) private _requiredSignatures;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Constructor
     * @dev initialize a few select state variables (token/proposal ID's have to start from non-zero positive int)
     */
    constructor() ERC721("MultisigNFT", "MSNFT"){
        _tokenId = 1;
        _proposalId = 1;
        _proposalCount = 0;
    }

    /**
     * @dev mints a new multi-signature NFT
     * @param coSigners array of acc addr's that can propose and vote on changes
     * @param requiredSignatures the required num of sigs in order to approve a given proposal
     */
    function mint(address[] calldata coSigners, uint8 requiredSignatures) public {
        require(requiredSignatures <= coSigners.length, "Required signatures cannot be greater than number of co-signers");
        super._safeMint(msg.sender, _tokenId);
        _coSigners[_tokenId] = coSigners;

        for (uint i = 0; i < coSigners.length; i++) {
            _isCoSigner[coSigners[i]] = true;
        }

        _requiredSignatures[_tokenId] = requiredSignatures;

        _owners[_tokenId] = msg.sender;
        _isOwner[msg.sender] = true;
        
        _tokenId += 1;
    }

    /**
     * @dev check to see if an address is a coSigner of a given tokenId
     * @param tokenId the ID of the NFT we are checking
     * @param addr the address we wish to check
     * @return bool is the given address a co-signer?
     */
    function isCoSigner(uint256 tokenId, address addr) private view returns (bool) {
        for (uint i = 0; i < _coSigners[tokenId].length; i++) {
            if (_coSigners[tokenId][i] == addr) {
                return true;
            }
        }
    }

    /**
     * @dev check to see if an address is an owner of a given tokenId
     * @param tokenId the NFT ID
     * @param addr the address we wish to check
     * @return bool is the given address an owner?
     */
    function isOwner(uint256 tokenId, address addr) private view returns (bool) {
        if (_owners[tokenId] == addr) {
            return true;
        }
    }

    /**
     * @dev submit a proposal
     * @param tokenId token ID to target
     * @param action the action to take if the proposal passes
     * @notice (string[] params) length and content depends on (uint8 action)
     */
    function propose(uint256 tokenId, uint8 action, string[] calldata params) public {
        require(isCoSigner(tokenId, msg.sender) == true || isOwner(tokenId, msg.sender) == true);
        Proposal memory proposal = Proposal(msg.sender, tokenId, action, params, false);
        _proposals[tokenId] = proposal;
        _proposalId += 1;
        _proposalCount += 1;
    }

    /**
     * @dev cast a vote on a proposal
     * @param proposalId the proposal to vote on
     * @param approval true/false value representing vote
     */
    function vote(uint256 proposalId, bool approval) public {
        Proposal storage proposal = _proposals[proposalId];
        uint256 tokenId = proposal.tokenId;
        require(isCoSigner(tokenId, msg.sender) == true || isOwner(tokenId, msg.sender) == true, "Must be an owner/co-signer to vote on proposals");
        require(_coSigners[tokenId].length > 0, "No co-signers found");
        _votes[proposalId][msg.sender] = approval;

        uint approvalCount = 0;

        for (uint i = 0; i < _coSigners[tokenId].length; i++) {
            if (_votes[proposalId][_coSigners[tokenId][i]] == true) {
                approvalCount += 1;
            } else if (_votes[proposalId][_owners[tokenId]] == true) {
                approvalCount += 1;
            }
        }

        if (approvalCount >= _requiredSignatures[tokenId]) {
            proposal.isApproved = true;
            
            if (proposal.action == 1) {
                super._burn(tokenId);
            }
        }

    }

    /**
     * @dev retrieve a proposal from memory
     * @param proposalId the ID of the proposal being retrieved
     * @return Proposal returns struct of given proposal
     */
    function getProposal(uint256 proposalId) public view returns (address, uint256, uint32, bool) {
        Proposal storage proposal = _proposals[proposalId];
        return (proposal.proposer, proposal.tokenId, proposal.action, proposal.isApproved);
    }

    /**
     * @dev retrieve proposal count from memory
     * @return uint256 returns current proposal count
     */
    function getProposalCount() public view returns (uint256) {
        return _proposalCount;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

}