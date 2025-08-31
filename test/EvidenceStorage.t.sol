// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/EvidenceStorage.sol";

contract EvidenceStorageTest is Test {
    EvidenceStorage public evidenceStorage;
    address public testUser = address(0x123);

    function setUp() public {
        evidenceStorage = new EvidenceStorage();
    }

    function testCreateEvidence() public {
        //记录初始状态
        uint256 initialEvidenceCount = evidenceStorage.getEvidenceCount();
        assertEq(initialEvidenceCount, 0,"Initial evidence count should be zero.");
        
        //切换测试用户
        vm.prank(testUser);

        // 创建存证
        string memory content = "This is a test evidence.";
        evidenceStorage.createEvidence(content);

        // 验证状态变化
        uint256 newCount = evidenceStorage.getEvidenceCount();
        assertEq(newCount, initialEvidenceCount + 1, "Evidence count should increase by 1");
        
         // 验证存证内容
        (address creator, string memory storedContent, uint256 timestamp) = evidenceStorage.getEvidence(0);
        assertEq(creator, testUser,"Creator should be test user");
        assertEq(storedContent, content,"Content should match input");
        assertGt(timestamp, 0,"Timestamp should be set");
        assertLe(timestamp, block.timestamp, "Timestamp should not be in future");

         // 验证用户映射更新
        uint256 userEvidenceCount = evidenceStorage.getUserEvidenceCount(testUser);
        assertEq(userEvidenceCount, 1,"User evidence count should be 1"); 

        // 验证用户存证ID列表   
        uint256[] memory userEvidenceIds = evidenceStorage.getUserEvidenceIds(testUser);
        assertEq(userEvidenceIds.length, 1,"User evidence IDs length should be 1");
        assertEq(userEvidenceIds[0], 0,"First evidence ID should be 0"); 
    }
    

    


}