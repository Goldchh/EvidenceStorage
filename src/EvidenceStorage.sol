// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EvidenceStorage {
    struct Evidence {
        address creator;   
        string content;
        uint256 timestamp;
    }

    Evidence[] public evidences;
    mapping(address => uint256[]) public userEvidences;

    event EvidenceCreated(uint256 indexed evidenceId, address indexed creator, string content, uint256 timestamp);

    //创建存证
    function createEvidence(string memory content) public {
        evidences.push(Evidence({
            creator:msg.sender,
            content:content,
            timestamp:block.timestamp
        }));
        
        uint256 evidenceId = evidences.length-1;
        // 将存证ID添加到用户的存证列表中
        userEvidences[msg.sender].push(evidenceId);

        emit EvidenceCreated(evidenceId, msg.sender, content, block.timestamp);
    }


    function getEvidenceCount() public view returns (uint256) {
        return evidences.length;
    }

    //获取用户存证总数
    function getUserEvidenceCount(address user) public view returns (uint256) {
        return userEvidences[user].length;
    }
    
    function getEvidence(uint256 evidenceId) public view returns (address, string memory, uint256) {
        require(evidenceId < evidences.length, "Evidence does not exist");
        Evidence memory evidence = evidences[evidenceId];
        return (evidence.creator, evidence.content, evidence.timestamp);
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