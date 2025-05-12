// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract ChainTalk is Ownable, ReentrancyGuard {
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        bool isDeleted;
    }
    struct EditRequest {
        uint256 messageId;
        address requester;
        string newContent;
        bool isApproved;
    }
    mapping(uint256 => Message) public messages;
    mapping(uint256 => EditRequest) public editRequests;
    uint256 public messageCount;
    uint256 public editRequestCount;
    event MessagePosted(uint256 indexed messageId, address indexed author, string content);
    event EditRequested(uint256 indexed messageId, address indexed requester, string newContent);
    event EditApproved(uint256 indexed messageId, string newContent);
    event MessageDeleted(uint256 indexed messageId);
    constructor() Ownable(msg.sender) {}

    function postMessage(string memory _content) public nonReentrant returns (uint256) {
        require(bytes(_content).length > 0, "Message cannot be empty");
        messageCount++;
        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            isDeleted: false
        });
        emit MessagePosted(messageCount, msg.sender, _content);
        return messageCount;
    }
    function getMessage(uint256 _messageId) public view returns (Message memory) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message has been deleted");
        return messages[_messageId];
    }
    function getAllMessages() public view returns (Message[] memory) {
        Message[] memory activeMessages = new Message[](messageCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= messageCount; i++) {
            if (!messages[i].isDeleted) {
                activeMessages[count] = messages[i];
                count++;
            }
        }
        assembly {
            mstore(activeMessages, count)
        }
        return activeMessages;
    }
    function requestMessageEdit(uint256 _messageId, string memory _newContent) public nonReentrant {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message has been deleted");
        require(messages[_messageId].author == msg.sender, "Only message author can request edit");
        require(bytes(_newContent).length > 0, "New content cannot be empty");
        editRequestCount++;
        editRequests[editRequestCount] = EditRequest({
            messageId: _messageId,
            requester: msg.sender,
            newContent: _newContent,
            isApproved: false
        });
        emit EditRequested(_messageId, msg.sender, _newContent);
    }
    function approveMessageEdit(uint256 _editRequestId) public onlyOwner {
        require(_editRequestId > 0 && _editRequestId <= editRequestCount, "Invalid edit request ID");
        EditRequest storage editRequest = editRequests[_editRequestId];
        require(!editRequest.isApproved, "Edit request already approved");
        Message storage message = messages[editRequest.messageId];
        message.content = editRequest.newContent;
        editRequest.isApproved = true;
        emit EditApproved(editRequest.messageId, editRequest.newContent);
    }
    function getPendingEditRequests() public view returns (EditRequest[] memory) {
        EditRequest[] memory pendingRequests = new EditRequest[](editRequestCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= editRequestCount; i++) {
            if (!editRequests[i].isApproved) {
                pendingRequests[count] = editRequests[i];
                count++;
            }
        }
        assembly {
            mstore(pendingRequests, count)
        }
        return pendingRequests;
    }
    function deleteMessage(uint256 _messageId) public onlyOwner {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message already deleted");
        messages[_messageId].isDeleted = true;
        emit MessageDeleted(_messageId);
    }
}
