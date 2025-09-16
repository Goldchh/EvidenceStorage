// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../script/DeployEvidenceStorage.s.sol";
import "../src/EvidenceStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract EvidenceStorageFunctionalTest is Test {
    EvidenceStorage public evidenceStorage;
    // 测试用户地址
    address public userA = makeAddr("userA");
    address public userB = makeAddr("userB");
    address public randomUser = makeAddr("randomUser");

    // 测试数据
    bytes32 public constant VALID_HASH_1 = keccak256("Evidence Content 1");
    bytes32 public constant VALID_HASH_2 = keccak256("Evidence Content 2");
    bytes32 public constant ZERO_HASH = 0;

    uint256 public constant EVIDENCE_COUNT =  5;

    function setUp() public {
       
        //DeployEvidenceStorage deployer = new DeployEvidenceStorage();
        evidenceStorage = new EvidenceStorage(address(this));

    }


    // ========== createEvidence 测试 ========== //

    // Happy Path: 成功创建公开存证
    function test_CreateEvidence_Success_Public() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);

        // 验证状态更新
        assertEq(evidenceStorage.getEvidenceCount(), 1);
        assertEq(evidenceStorage.getUserEvidenceCount(userA), 1);
        
        // 验证存证详情
        (address creator, bytes32 contentHash, uint256 timestamp, bool isPublic) = evidenceStorage.getEvidence(0);
        assertEq(creator, userA);
        assertEq(contentHash, VALID_HASH_1);
        assertTrue(isPublic);
        assertTrue(timestamp > 0);
    }

    // Happy Path: 成功创建私有存证
    function test_CreateEvidence_Success_Private() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, false);

        (, , , bool isPublic) = evidenceStorage.getEvidence(0);
        assertFalse(isPublic);
    }

    // Unhappy Path: 零哈希应回滚
    function testRevert_CreateEvidence_zeroHash() public {
        bytes32 zeroHash = 0;
        bool isPublic = true;

        vm.prank(userA);
        vm.expectRevert("Content hash cannot be zero");
        evidenceStorage.createEvidence(zeroHash, isPublic);
    }

    //Unhappy Path: 同一用户重复存证应回滚
    function testRevert_CreateEvidence_duplicateHashSameUser() public {
        vm.startPrank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);

        vm.expectRevert("You have already stored evidence for this file content. Operation not allowed.");
        evidenceStorage.createEvidence(VALID_HASH_1, false);//相同哈希，不同可见性。

        vm.stopPrank();

    }

  
    //// Happy Path: 不同用户可存证相同内容
    function test_CreateEvidence_DifferentUsers_SameContent() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);

        vm.prank(userB);
        evidenceStorage.createEvidence(VALID_HASH_1, false); // 不同用户可以存储相同内容    

        assertEq(evidenceStorage.getEvidenceCount(), 2);
    }

    //Fuzz Test 随机输入测试
    function testFuzz_CreateEvidence_Fuzzing(bytes32 _contentHash,bool _isPublic) public {
        vm.assume(_contentHash != ZERO_HASH);

        vm.prank(userA);
        evidenceStorage.createEvidence(_contentHash, _isPublic);

        (address creator, bytes32 contentHash, , bool isPublic) = evidenceStorage.getEvidence(0);
        assertEq(isPublic, _isPublic);
        assertEq(contentHash, _contentHash);
    }

    // ========== setEvidenceVisibility 测试 ========== //
    function test_SetEvidenceVisibility_Success() public {
        vm.startPrank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, false); // 初始为私有

        evidenceStorage.setEvidenceVisibility(0, true); // 修改为公开
        (, , , bool isPublic) = evidenceStorage.getEvidence(0);
        console.log("ispublic==========",isPublic);
        assertTrue(isPublic);

        // evidenceStorage.setEvidenceVisibility(0, false); // 公开 -> 私有
        // (, , ,bool _isPublic) = evidenceStorage.getEvidence(0);
        // assertFalse(_isPublic);
        vm.stopPrank();
    }

    //unHappy path 无效ID应回滚
    function testRevert_SetEvidenceVisibility_InvalidId() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);

        vm.prank(userA);
        vm.expectRevert("EvidenceStorage: Evidence does not exist");
        evidenceStorage.setEvidenceVisibility(1, false); // ID 1 不存在
    }   

    // Permission Test: 非创建者无权修改
    function testRevert_SetEvidenceVisibility_NotCreator() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);

        vm.prank(userB);
        vm.expectRevert("EvidenceStorage: Only evidence creator can change visibility");
        evidenceStorage.setEvidenceVisibility(0, false); // 非创建者尝试修改
    }

      // ========== getEvidence 权限测试 ========== //

      //Hapyy path:创建者可查看自己的私有存证
    function test_GetEvidence_CreatorCanViewPrivate() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, false); // 私有存证

        vm.prank(userA);
        (address creator, bytes32 contentHash, , bool isPublic) = evidenceStorage.getEvidence(0);
        assertEq(creator, userA);
        assertEq(contentHash, VALID_HASH_1);
        assertFalse(isPublic);
    }

    function testRevert_GetEvidence_OtherViewPrivate() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, false); // 私有存证

        vm.prank(userB);
        vm.expectRevert("EvidenceStorage: Evidence is private");
        evidenceStorage.getEvidence(0); // 非创建者尝试查看私有存证
    }

    function test_GetEvidence_AnyoneViewPublic() public {
        vm.prank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true); // 公开存证
    
        vm.prank(randomUser);
        (address creator,,,bool isPublic) = evidenceStorage.getEvidence(0); // 随机用户查看公开存证
        assertEq(creator, userA);
        assertTrue(isPublic);
    }


    // ========== 批量功能测试 ========== //

    //Happy Path:批量获取ID
    function test_GetUserEvidenceIds() public {
        vm.startPrank(userA);
        evidenceStorage.createEvidence(VALID_HASH_1, true);
        evidenceStorage.createEvidence(VALID_HASH_2, false);
        vm.stopPrank();

        uint256[] memory ids = evidenceStorage.getUserEvidenceIds(userA);
        assertEq(ids.length, 2);
        assertEq(ids[0], 0);
        assertEq(ids[1], 1);    
    }


     // Edge Case: 空用户返回空数组
     function test_GetUserEvidenceIds_Empty() public {
        uint256[] memory ids = evidenceStorage.getUserEvidenceIds(userA);
        assertEq(ids.length, 0); // 用户没有存证时返回空数组
     }

     // ========== 测试边界情况 ========== //
     function test_EmptyUserEvidenceIds() public {
        uint256[] memory ids = evidenceStorage.getUserEvidenceIds(userA);
        assertEq(ids.length, 0,"Should return empty array for user with no evidences"); // 用户没有存证时返回空数组
     }


       // ========== 模糊测试 ========== //

       function testFuzz_CreateEvidence(bytes32 _contentHash,bool _isPublic) public {
            vm.assume(_contentHash !=0);

            vm.prank(userA);
            evidenceStorage.createEvidence(_contentHash, _isPublic);    

            (,,,bool isPublic) = evidenceStorage.getEvidence(0);

            assertEq(isPublic, _isPublic, "Visibility should match input");
            assertEq(evidenceStorage.getEvidenceCount(),1,"Evidence count should be 1");
       }








}