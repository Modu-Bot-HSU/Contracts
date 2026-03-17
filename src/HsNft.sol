// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 한성대학교 NFT 상점
 * @author woojo230 (Jun)
 * @notice 유저가 20개의 고유 NFT 중 하나를 선택해 HS 코인으로 구매
 * @dev OpenZeppelin의 ERC721 및 Ownable을 상속받아 구현
 */
contract HsNft is ERC721, Ownable {
    IERC20 public immutable i_hsToken;
    string private s_baseUri;

    mapping(uint256 => bool) public s_isSold;

    /**
     * @notice 유저의 nft 거래 내역을 트레킹 하기 위한 이벤트
     * @param buyer 해당 nft를 구매한 유저의 주소
     * @param index 선택한 NFT 디자인의 인덱스 (0~19)
     * @param tokenId 발행된 NFT의 고유 ID (이 프로젝트에서는 index와 동일)
     * @param price 각 NFT 가격
     */
    event NftPurchased(
        address indexed buyer,
        uint256 indexed index,
        uint256 tokenId,
        uint256 price
    );

    constructor(
        address hsTokenAddress,
        string memory baseUri
    ) ERC721("Univ 3D", "U3D") Ownable(msg.sender) {
        i_hsToken = IERC20(hsTokenAddress);
        s_baseUri = baseUri;
    }

    /**
     * @dev ERC721 표준 함수를 오버라이드하여 Base URI를 반환
     * 해당 함수가 'baseUri + tokenId' 형태로 메타데이터 주소를 완성
     */
    function _baseURI() internal view override returns (string memory) {
        return s_baseUri;
    }

    /**
     * @notice 관리자(서버)가 유저 대신 가스비를 내고 구매를 진행
     * @param user 실제 NFT를 받을 유저의 주소
     * @param index 구매할 NFT 번호
     */
    function buyNftForUser(
        address user,
        uint256 index,
        uint256 price
    ) public onlyOwner {
        require(index < 20, "Out of range");
        require(!s_isSold[index], "Already sold");

        // 유저에게 사전에 'Approve' 승인을 받아야함
        require(
            i_hsToken.transferFrom(user, address(this), price),
            "Token transfer failed"
        );

        s_isSold[index] = true;
        _safeMint(user, index);

        emit NftPurchased(user, index, index, price);
    }

    /**
     * @notice 특정 NFT 디자인의 현재 소유주를 확인
     * @param index 확인하려는 디자인의 인덱스 (0~19)
     * @return 소유자의 주소 (판매되지 않았을 경우 address(0) 반환)
     */
    function getNftOwner(uint256 index) public view returns (address) {
        // 아직 팔리지 않은 디자인이라면 주소 0을 반환하여 에러 방지
        if (!s_isSold[index]) {
            return address(0);
        }
        // 이미 팔린 디자인이라면 표준 ownerOf 함수 호출
        return ownerOf(index);
    }

    /**
     * @notice 20개 전체 디자인의 판매 여부 상태를 한 번에 확인
     * @return 20개 디자인의 판매 여부를 담은 배열
     */
    function getInventoryStatus() public view returns (bool[20] memory) {
        bool[20] memory status;
        for (uint256 i = 0; i < 5; i++) {
            status[i] = s_isSold[i];
        }
        return status;
    }

    /**
     * @notice Base URI를 변경하는 함수 (서버 이전이나 IPFS 경로 변경 시 사용)
     * @param newBaseUri 새로운 IPFS 폴더 주소 (끝에 / 포함 권장)
     */
    function setBaseURI(string memory newBaseUri) public onlyOwner {
        s_baseUri = newBaseUri;
    }
}
