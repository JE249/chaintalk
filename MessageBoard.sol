// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ChainTalk
 * @dev A smart contract for a decentralized message board with advanced features
 */
contract ChainTalk is Ownable, ReentrancyGuard {
    // Struct to represent a message
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        bool isDeleted;
    }

    // Struct to represent an edit request
    struct EditRequest {
        uint256 messageId;
        address requester;
        string newContent;
        bool isApproved;
    }

    // Mappings to store messages and edit requests
    mapping(uint256 => Message) public messages;
    mapping(uint256 => EditRequest) public editRequests;

    // Counters and tracking variables
    uint256 public messageCount;
    uint256 public editRequestCount;

    // Events for contract actions
    event MessagePosted(uint256 indexed messageId, address indexed author, string content);
    event EditRequested(uint256 indexed messageId, address indexed requester, string newContent);
    event EditApproved(uint256 indexed messageId, string newContent);
    event MessageDeleted(uint256 indexed messageId);

    // Constructor inherits from Ownable
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Post a new message
     * @param _content The content of the message
     * @return The ID of the newly created message
     */
    function postMessage(string memory _content) public nonReentrant returns (uint256) {
        // Ensure message is not empty
        require(bytes(_content).length > 0, "Message cannot be empty");

        // Increment message count and create new message
        messageCount++;
        messages[messageCount] = Message({
            id: messageCount,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            isDeleted: false
        });

        // Emit event
        emit MessagePosted(messageCount, msg.sender, _content);

        return messageCount;
    }

    /**
     * @dev Retrieve a specific message by ID
     * @param _messageId The ID of the message to retrieve
     * @return The message struct
     */
    function getMessage(uint256 _messageId) public view returns (Message memory) {
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message has been deleted");
        return messages[_messageId];
    }

    /**
     * @dev Retrieve all non-deleted messages
     * @return An array of all active messages
     */
    function getAllMessages() public view returns (Message[] memory) {
        // Create a dynamic array to store active messages
        Message[] memory activeMessages = new Message[](messageCount);
        uint256 count = 0;

        // Iterate and collect non-deleted messages
        for (uint256 i = 1; i <= messageCount; i++) {
            if (!messages[i].isDeleted) {
                activeMessages[count] = messages[i];
                count++;
            }
        }

        // Resize array to fit actual count
        assembly {
            mstore(activeMessages, count)
        }

        return activeMessages;
    }

    /**
     * @dev Request an edit to a message
     * @param _messageId The ID of the message to edit
     * @param _newContent The proposed new content
     */
    function requestMessageEdit(uint256 _messageId, string memory _newContent) public nonReentrant {
        // Validate message and requester
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message has been deleted");
        require(messages[_messageId].author == msg.sender, "Only message author can request edit");
        require(bytes(_newContent).length > 0, "New content cannot be empty");

        // Create edit request
        editRequestCount++;
        editRequests[editRequestCount] = EditRequest({
            messageId: _messageId,
            requester: msg.sender,
            newContent: _newContent,
            isApproved: false
        });

        // Emit event
        emit EditRequested(_messageId, msg.sender, _newContent);
    }

    /**
     * @dev Approve an edit request (only owner)
     * @param _editRequestId The ID of the edit request to approve
     */
    function approveMessageEdit(uint256 _editRequestId) public onlyOwner {
        // Validate edit request
        require(_editRequestId > 0 && _editRequestId <= editRequestCount, "Invalid edit request ID");
        EditRequest storage editRequest = editRequests[_editRequestId];
        require(!editRequest.isApproved, "Edit request already approved");

        // Update message and mark edit request as approved
        Message storage message = messages[editRequest.messageId];
        message.content = editRequest.newContent;
        editRequest.isApproved = true;

        // Emit event
        emit EditApproved(editRequest.messageId, editRequest.newContent);
    }

    /**
     * @dev Retrieve all pending edit requests
     * @return An array of pending edit requests
     */
    function getPendingEditRequests() public view returns (EditRequest[] memory) {
        // Create a dynamic array to store pending requests
        EditRequest[] memory pendingRequests = new EditRequest[](editRequestCount);
        uint256 count = 0;

        // Iterate and collect pending edit requests
        for (uint256 i = 1; i <= editRequestCount; i++) {
            if (!editRequests[i].isApproved) {
                pendingRequests[count] = editRequests[i];
                count++;
            }
        }

        // Resize array to fit actual count
        assembly {
            mstore(pendingRequests, count)
        }

        return pendingRequests;
    }

    /**
     * @dev Delete a message (only owner)
     * @param _messageId The ID of the message to delete
     */
    function deleteMessage(uint256 _messageId) public onlyOwner {
        // Validate message
        require(_messageId > 0 && _messageId <= messageCount, "Invalid message ID");
        require(!messages[_messageId].isDeleted, "Message already deleted");

        // Mark message as deleted
        messages[_messageId].isDeleted = true;

        // Emit event
        emit MessageDeleted(_messageId);
    }
} 