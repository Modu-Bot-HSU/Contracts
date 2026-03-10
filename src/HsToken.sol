// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 대학교 챗봇 기여 보상 토큰 (HS)
 * @author woojo230 (Jun)
 * @notice 해당 컨트랙트는 챗봇 학습에 기여한 학생들에게 보상을 주기 위한 ERC-20 토큰
 * @dev OpenZeppelin의 ERC20 및 Ownable을 상속받아 구현
 */

contract HsToken is ERC20, Ownable {
    constructor(
        uint256 initialSupply
    ) ERC20("HSToken", "HS") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice 보상이 지급되었을 때 발생하는 이벤트
     * @param user 보상을 받은 학생의 지갑 주소
     * @param amount 지급된 토큰의 양
     */
    event RewardIssued(address indexed user, uint256 amount);

    /**
     * @notice Owner만 토큰을 발행할 수 있도록 하는 함수
     * @param to 토큰을 지급받을 유저의 주소
     * @param amount 지급할 토큰의 총량
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice 특정 유저의 HS 토큰 잔액을 확인
     * @dev ERC20 표준의 balanceOf를 래핑한 함수
     * @param user 조회할 유저의 지갑 주소
     * @return 유저가 보유한 토큰의 양 (18자리 소수점 포함)
     */
    function getBalanceOf(address user) public view returns (uint256) {
        return balanceOf(user);
    }

    /**
     * @notice 챗봇 학습 기여에 대한 보상을 유저에게 지급
     * @dev 관리자(Owner) 권한이 있어야 실행 가능하며, 내부적으로 _mint를 호출
     * @param user 보상을 받을 학생의 주소
     * @param amount 지급할 토큰 수량 (wei 단위)
     */
    function rewardUser(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "Invalid address");
        require(amount > 0, "Reward amount must be greater than 0");

        // 유저에게 토큰 추가 발행
        _mint(user, amount);

        // 이벤트 발생시켜서 블록체인 상에 코인이 지급된 내역을 로깅
        emit RewardIssued(user, amount);
    }
}
