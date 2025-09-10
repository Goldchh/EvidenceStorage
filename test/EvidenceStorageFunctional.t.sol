// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../script/DeployEvidenceStorage.s.sol";
import "../src/EvidenceStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract EvidenceStorageFunctionalTest is Test {
    EvidenceStorage public evidenceStorage;
    // 测试用户地址
    address public constant TEST_USER = address(0x1);
    address public constant ANOTHER_USER = address(0x2);
    address public constant THIRD_USER = address(0x3);

    // 测试内容常量
    string public constant SAMPLE_CONTENT = "Test evidence content";
    string public constant EMPTY_CONTENT = "";
    string public constant LONG_CONTENT = "This is a very long evidence content that should be properly stored in the blockchain for testing purposes";
    
    uint256 public constant EVIDENCE_COUNT =  5;

    function setUp() public {
       
        //DeployEvidenceStorage deployer = new DeployEvidenceStorage();
        evidenceStorage = new EvidenceStorage();

    }


    // 基础测试数据：单个用户单个存证
    function createSingleEvidence() internal {
        vm.prank(TEST_USER);
        evidenceStorage.createEvidence(generateHashFromString(SAMPLE_CONTENT));
    }

     // 多用户测试数据：3个用户各1个存证
    function createMultiUserEvidences() internal {
        console.log("createMultiUserEvidences-------");
        vm.prank(TEST_USER);
      
        evidenceStorage.createEvidence(generateHashFromString("User1 Evidence"));
        
        vm.prank(ANOTHER_USER);
        evidenceStorage.createEvidence(generateHashFromString("User2 Evidence"));
        
        vm.prank(THIRD_USER);
        evidenceStorage.createEvidence(generateHashFromString("User3 Evidence"));
    }
    
     // 单用户多存证数据：一个用户多个存证

    function createUserWithMultipleEvidences(address user, uint256 count) internal {
        console.log("createEdgeCaseEvidences-------");
        for (uint256 i = 0; i < count; i++) {
            vm.prank(user);
            string memory evidenceContent = string(abi.encodePacked("Evidence ", Strings.toString(i)));
            bytes32 contentHash = keccak256(bytes(evidenceContent));
            evidenceStorage.createEvidence(contentHash);
        }
    }

     // 边界情况测试数据
    function createEdgeCaseEvidences() internal {
        console.log("createEdgeCaseEvidences-------");
        // 空内容
        vm.prank(TEST_USER);
        evidenceStorage.createEvidence(generateHashFromString(EMPTY_CONTENT));
        
        // 长内容
        vm.prank(ANOTHER_USER);
        evidenceStorage.createEvidence(generateHashFromString(LONG_CONTENT));
        
        // 特殊字符
        vm.prank(THIRD_USER);
        evidenceStorage.createEvidence(generateHashFromString("Special!@#$%^&*()_+{}|:<>?[];',./"));
        
        console.logBytes32(generateHashFromString("Special!@#$%^&*()_+{}|:<>?[];',./"));

    }

    // 完整测试环境：组合所有数据
    function createCompleteTestEnvironment() internal {
        createMultiUserEvidences();
        createUserWithMultipleEvidences(TEST_USER, 3);
        createEdgeCaseEvidences();
    }

    function generateHashFromString(string memory _str) public pure returns (bytes32) {
        // 方法1: 使用 abi.encodePacked 将字符串打包编码为 bytes
        return keccak256(abi.encodePacked(_str));
    }
    // 验证存证内容
    function verifyEvidenceContent(uint256 evidenceId, address expectedCreator, string memory expectedContent) internal view {
        (address creator, bytes32 contentHash, uint256 timestamp) = evidenceStorage.getEvidence(evidenceId);
        bytes32 expectedContentHash = keccak256(abi.encodePacked(expectedContent));

        assertEq(creator, expectedCreator, "Creator mismatch");
        assertEq(contentHash, expectedContentHash, "Content mismatch");
        assertGt(timestamp, 0, "Timestamp should be positive");
        
    }

     // 验证用户存证数量
    function verifyUserEvidenceCount(address user, uint256 expectedCount) internal view {
        uint256 actualCount = evidenceStorage.getUserEvidenceCount(user);
        assertEq(actualCount, expectedCount, "User evidence count mismatch");
    }
    

    // 测试1: 基础存证创建
    function testEvidenceCreation() public {
        // 初始状态验证
        assertEq(evidenceStorage.getEvidenceCount(), 0, "Initial count should be 0");
        
        // 创建测试数据
        createSingleEvidence();
        
        // 验证状态变化
        assertEq(evidenceStorage.getEvidenceCount(), 1, "Count should increase after creation");
        verifyEvidenceContent(0, TEST_USER, SAMPLE_CONTENT);
    }

    // 测试2: 多用户场景
    function testMultipleUsers() public {
        createMultiUserEvidences();
        
        // 验证总数量
        assertEq(evidenceStorage.getEvidenceCount(), 3, "Should have 3 evidences total");
        
        // 验证各用户存证数量
        verifyUserEvidenceCount(TEST_USER, 1);
        verifyUserEvidenceCount(ANOTHER_USER, 1);
        verifyUserEvidenceCount(THIRD_USER, 1);
        
        // 验证存证内容
        verifyEvidenceContent(0, TEST_USER, "User1 Evidence");
        verifyEvidenceContent(1, ANOTHER_USER, "User2 Evidence");
        verifyEvidenceContent(2, THIRD_USER, "User3 Evidence");
    }

    // 测试3: 单用户多存证
    function testSingleUserMultipleEvidences() public {
        uint256 evidenceCount = 4;
        createUserWithMultipleEvidences(TEST_USER, evidenceCount);
        
        // 验证数量
        assertEq(evidenceStorage.getEvidenceCount(), evidenceCount, "Total evidence count mismatch");
        verifyUserEvidenceCount(TEST_USER, evidenceCount);
        
        // 验证内容
        for (uint256 i = 0; i < evidenceCount; i++) {
            verifyEvidenceContent(i, TEST_USER, string(abi.encodePacked("Evidence ", Strings.toString(i))));
        }
    }


    // 测试4: 边界情况处理
    function testEdgeCases() public {
        createEdgeCaseEvidences();
        
        // 验证空内容
        verifyEvidenceContent(0, TEST_USER, EMPTY_CONTENT);
        
        // 验证长内容
        verifyEvidenceContent(1, ANOTHER_USER, LONG_CONTENT);
        
        // 验证特殊字符
        verifyEvidenceContent(2, THIRD_USER, "Special!@#$%^&*()_+{}|:<>?[];',./");
    }

    // 测试5: 事件触发
    function testEvidenceCreatedEvent() public {
        // 期望事件触发
        vm.expectEmit(true, true, false, true);
        emit EvidenceStorage.EvidenceCreated(0, TEST_USER, keccak256(abi.encodePacked(SAMPLE_CONTENT)), block.timestamp);
        
        createSingleEvidence();
    }

    // 测试6: 错误情况处理
    function testErrorCases() public {
        // 获取不存在的存证应该revert
        vm.expectRevert("Evidence does not exist");
        evidenceStorage.getEvidence(0);
        
        // 创建存证后再次测试边界
        createSingleEvidence();
        
        // 访问存在的存证应该成功
        evidenceStorage.getEvidence(0);
        
        // 访问不存在的索引应该revert
        vm.expectRevert("Evidence does not exist");
        evidenceStorage.getEvidence(1);
    }


    // 测试7: 复杂场景集成测试
    function testComplexIntegration() public {
        createCompleteTestEnvironment();
        
        // 验证总数量 (3多用户 + 3单用户多存证 + 3边界情况 = 9)
        assertEq(evidenceStorage.getEvidenceCount(), 9, "Total evidence count mismatch");
        

        // 验证用户1有4个存证 (1多用户 + 3单用户多存证)
        verifyUserEvidenceCount(TEST_USER, 5);
        
        // 验证用户2有2个存证 (1多用户 + 1边界情况)
        verifyUserEvidenceCount(ANOTHER_USER, 2);
        
        // 验证用户3有2个存证 (1多用户 + 1边界情况)
        verifyUserEvidenceCount(THIRD_USER, 2);
        
        // 验证特定存证内容
       
        verifyEvidenceContent(0, TEST_USER, "User1 Evidence");
        
        verifyEvidenceContent(3, TEST_USER, "Evidence 0");  
        
        verifyEvidenceContent(6, TEST_USER, "");
    }

    // 测试9: 用户存证ID映射验证
    function testUserEvidenceMapping() public {
        createMultiUserEvidences();
        
        // 验证用户存证ID列表
        uint256[] memory user1Evidences = evidenceStorage.getUserEvidenceIds(TEST_USER);
        uint256[] memory user2Evidences = evidenceStorage.getUserEvidenceIds(ANOTHER_USER);
        uint256[] memory user3Evidences = evidenceStorage.getUserEvidenceIds(THIRD_USER);
        
        assertEq(user1Evidences.length, 1, "User1 should have 1 evidence ID");
        assertEq(user2Evidences.length, 1, "User2 should have 1 evidence ID");
        assertEq(user3Evidences.length, 1, "User3 should have 1 evidence ID");
        
        assertEq(user1Evidences[0], 0, "User1's evidence should have ID 0");
        assertEq(user2Evidences[0], 1, "User2's evidence should have ID 1");
        assertEq(user3Evidences[0], 2, "User3's evidence should have ID 2");
    }








}