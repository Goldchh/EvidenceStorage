// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Test.sol";
// 引入 Ownable 合约
import "@openzeppelin/contracts/access/Ownable.sol";


contract EvidenceStorage is Ownable {

    struct Evidence {
        address creator;   
        uint256 timestamp;
        bytes32 contentHash;
        bool    isPublic;
    }

    Evidence[] public evidences;
    // 核心修改：用户级唯一性检查映射
    // 格式：userUsedHashes[用户地址][文件哈希] => 是否已存证 (true/false)
    mapping(address => mapping(bytes32=>bool)) public userUsedHashes;

    mapping(address => uint256[]) public userEvidences;

    // // 新增一个映射，记录用户是否公开存证
    mapping(uint256 => bool) public isEvidencePublic;
    
    event EvidenceCreated(uint256 indexed evidenceId, address indexed creator, bytes32 contentHash,uint256 timestamp,bool isPublic);
    
     // 新增：事件，当存证的公开状态发生变化时触发
    event EvidenceVisibilitySet(uint256 indexed evidenceId, bool isPublic);

    constructor(address initialOwner) Ownable(initialOwner) {
        //TODO
    }
    //创建存证
    function createEvidence(bytes32  _contentHash,bool isPublic) public {
        require(_contentHash != 0, "Content hash cannot be zero");
        require(!userUsedHashes[msg.sender][_contentHash], "You have already stored evidence for this file content. Operation not allowed.");
        evidences.push(Evidence({
            creator:msg.sender,
            timestamp:block.timestamp,
            contentHash:_contentHash,
            isPublic:isPublic
        }));

        
        uint256 evidenceId = evidences.length-1;
        // 将存证ID添加到用户的存证列表中
        userEvidences[msg.sender].push(evidenceId);

        userUsedHashes[msg.sender][_contentHash] = true;

        isEvidencePublic[evidenceId] = isPublic; // 默认存证为公开

         // 触发存证创建事件

        emit EvidenceCreated(evidenceId, msg.sender, _contentHash,block.timestamp,isPublic);

    }

     /**
     * @notice 存证创建者可以修改其存证的可见性
     * @param _evidenceId 要修改的存证ID
     * @param _isPublic 新的可见性状态
     */
    function setEvidenceVisibility(uint256 _evidenceId, bool _isPublic) external {
        require(_evidenceId < evidences.length, "EvidenceStorage: Evidence does not exist");
        // 权限检查：只有存证的创建者可以修改其可见性
        console.log("_evidenceId===========");
        require(evidences[_evidenceId].creator == msg.sender, "EvidenceStorage: Only evidence creator can change visibility");
        console.log("evidences===========");
        isEvidencePublic[_evidenceId] = _isPublic;
        evidences[_evidenceId].isPublic = _isPublic;
        emit EvidenceVisibilitySet(_evidenceId, _isPublic);
    }



    function getEvidenceCount() public view returns (uint256) {
        return evidences.length;
    }

    //获取用户存证总数
    function getUserEvidenceCount(address user) public view returns (uint256) {
        return userEvidences[user].length;
    }
    
    function getEvidence(uint256 evidenceId) public view returns (address, bytes32 , uint256,bool) {
        require(evidenceId < evidences.length, "Evidence does not exist");
        Evidence memory evidence = evidences[evidenceId];

         require(
            isEvidencePublic[evidenceId] || 
            evidence.creator == msg.sender || 
            owner() == msg.sender,
            "EvidenceStorage: Evidence is private"
        );

        return (evidence.creator, evidence.contentHash, evidence.timestamp,evidence.isPublic);
    }

    /**
    * @notice 批量获取存证详情（替代原来的 getUserEvidences）
    * @dev 调用者指定要查询的ID数组，按需获取，避免Gas浪费。会逐一进行权限检查。
    * @param _evidenceIds 要查询的存证ID数组
    */
    function getEvidencesBatch(uint256[] calldata _evidenceIds) public view returns (
        address[] memory creators,
        bytes32[] memory contentHashes,
        uint256[] memory timestamps,
        bool[] memory visibilities
    ) {
        uint256 count = _evidenceIds.length;
        creators = new address[](count);
        contentHashes = new bytes32[](count);
        timestamps = new uint256[](count);
        visibilities = new bool[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 evidenceId = _evidenceIds[i];
            // 这里会调用 getEvidence 进行权限检查，如果无权限会revert
            (creators[i], contentHashes[i], timestamps[i], visibilities[i]) = getEvidence(evidenceId);
        }

        return (creators, contentHashes, timestamps, visibilities);
    }
       
    
    function getUserEvidenceIds(address user) public view returns (uint256[] memory) {
        return userEvidences[user];
    }

     /**
     * @notice 【新增】提供一个直接读取存证公开状态的方法，与之前外部映射的接口保持一致
     * @dev 这是为了兼容性考虑，如果之前有其他合约依赖这个映射接口
     * @param _evidenceId 存证ID
     */
    function isEvidencePublicF(uint256 _evidenceId) public view returns (bool) {

        require(_evidenceId < evidences.length, "Evidence does not exist");
        return evidences[_evidenceId].isPublic;

    }
}
    