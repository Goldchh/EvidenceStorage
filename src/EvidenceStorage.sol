// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


library EvidenceLib {
    function generateHash(string memory str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    
    function validateContent(string memory content) internal pure {
        require(bytes(content).length > 0, "Content cannot be empty");
        require(bytes(content).length <= 1024, "Content too long");
    }
}

contract EvidenceStorage {
    using EvidenceLib for string;

    struct Evidence {
        address creator;   
        uint256 timestamp;
        bytes32 contentHash;
    }

    Evidence[] public evidences;
    // 核心修改：用户级唯一性检查映射
    // 格式：userUsedHashes[用户地址][文件哈希] => 是否已存证 (true/false)
    mapping(address => mapping(bytes32=>bool)) public userUsedHashes;

    mapping(address => uint256[]) public userEvidences;
    
    event EvidenceCreated(uint256 indexed evidenceId, address indexed creator, bytes32 contentHash,uint256 timestamp);
    //创建存证
    function createEvidence(bytes32  _contentHash) public {
        require(!userUsedHashes[msg.sender][_contentHash], "You have already stored evidence for this file content. Operation not allowed.");
        evidences.push(Evidence({
            creator:msg.sender,
            timestamp:block.timestamp,
            contentHash:_contentHash
        }));

        
        uint256 evidenceId = evidences.length-1;
        // 将存证ID添加到用户的存证列表中
        userEvidences[msg.sender].push(evidenceId);

        userUsedHashes[msg.sender][_contentHash] = true;

        emit EvidenceCreated(evidenceId, msg.sender, _contentHash, block.timestamp);

    }



    function getEvidenceCount() public view returns (uint256) {
        return evidences.length;
    }

    //获取用户存证总数
    function getUserEvidenceCount(address user) public view returns (uint256) {
        return userEvidences[user].length;
    }
    
    function getEvidence(uint256 evidenceId) public view returns (address, bytes32 , uint256) {
        require(evidenceId < evidences.length, "Evidence does not exist");
        Evidence memory evidence = evidences[evidenceId];
        return (evidence.creator, evidence.contentHash, evidence.timestamp);
    }
    
    function getUserEvidenceIds(address user) public view returns (uint256[] memory) {
        return userEvidences[user];
    }
    
    function getUserEvidences(address user) public view returns (Evidence[] memory) {
        uint256 count = getUserEvidenceCount(user);
        Evidence[] memory userEvidenceList = new Evidence[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 evidenceId = userEvidences[user][i];
            userEvidenceList[i] = evidences[evidenceId];
        }
        
        return userEvidenceList;
    }
    




} 