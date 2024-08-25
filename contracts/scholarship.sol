// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Scholarship {
    address public admin;
    uint256 public scholarshipCount;
    uint256 public proposalCount;
    // IERC20 public token;
    
    enum Status {
        Open,
        Closed,
        Awarded,
        Proposed,
        Approved
    }

    struct ScholarshipDetail {
        string name;
        uint256 amount;
        address[] applicants;
        address awardedTo;
        uint256 minCGPA;
        uint256 minMarks12;
        Status status;
        uint256 deadline;
    }

    struct ScholarshipProposal {
        string name;
        uint256 amount;
        uint256 minCGPA;
        uint256 minMarks12;
        uint256 deadline;
        address proposer;
    }

    mapping(uint256 => ScholarshipDetail) public scholarships;
    mapping(uint256 => ScholarshipProposal) public proposals;
    mapping(address => uint256) public applicantCGPA;
    mapping(address => uint256) public applicant12Marks; 

    event ScholarshipCreated(uint256 id, string name, uint256 amount, uint256 minCGPA, uint256 minMarks12, uint256 deadline);
    event ApplicationSubmitted(uint256 scholarshipId, address applicant);
    event ScholarshipAwarded(uint256 scholarshipId, address student);
    event ProposalSubmitted(uint256 proposalId, string name, uint256 amount, uint256 minCGPA, uint256 minMarks12, uint256 deadline);
    event ProposalApproved(uint256 proposalId, uint256 scholarshipId);
    event ProposalRejected(uint256 proposalId);

    constructor() {
        admin = msg.sender;
        // token = IERC20(_token);
    }

    function createScholarship(string memory _name, uint256 _amount, uint256 _minCGPA, uint256 _minMarks12, uint256 _deadline) public {
        require(msg.sender == admin, "Only admin can create scholarships");
        scholarshipCount++;
        scholarships[scholarshipCount] = ScholarshipDetail({
            name: _name,
            amount: _amount,
            applicants: new address[](0) ,
            awardedTo: address(0),
            minCGPA: _minCGPA,
            minMarks12: _minMarks12,
            status: Status.Open,
            deadline: _deadline
        });
        emit ScholarshipCreated(scholarshipCount, _name, _amount, _minCGPA, _minMarks12, _deadline);
    }

    function proposeScholarship(string memory _name, uint256 _amount, uint256 _minCGPA, uint256 _minMarks12, uint256 _deadline) public {
        proposalCount++;
        proposals[proposalCount] = ScholarshipProposal({
            name: _name,
            amount: _amount,
            minCGPA: _minCGPA,
            minMarks12: _minMarks12,
            deadline: _deadline,
            proposer: msg.sender
        });
        emit ProposalSubmitted(proposalCount, _name, _amount, _minCGPA, _minMarks12, _deadline);
    }

    function approveProposal(uint256 _proposalId) public {
        require(msg.sender == admin, "Only admin can approve proposals");
        ScholarshipProposal storage proposal = proposals[_proposalId];
        require(proposal.amount > 0, "Proposal does not exist");
        
        scholarshipCount++;
        scholarships[scholarshipCount] = ScholarshipDetail({
            name: proposal.name,
            amount: proposal.amount,
            applicants: new address[](0) ,
            awardedTo: address(0),
            minCGPA: proposal.minCGPA,
            minMarks12: proposal.minMarks12,
            status: Status.Approved,
            deadline: proposal.deadline
        });
        delete proposals[_proposalId];
        emit ProposalApproved(_proposalId, scholarshipCount);
    }


    function applyForScholarship(uint256 _scholarshipId, uint256 _applicantCGPA, uint256 _applicant12Marks) public {
    ScholarshipDetail storage scholarship = scholarships[_scholarshipId];
    require(scholarship.status == Status.Open, "Scholarship is not open for applications");
    require(block.timestamp < scholarship.deadline, "Application deadline has passed");
    require(_applicantCGPA >= scholarship.minCGPA, "Applicant does not meet CGPA requirement");
    require(_applicant12Marks >= scholarship.minMarks12, "Applicant does not meet 12th grade marks requirement");

    applicantCGPA[msg.sender] = _applicantCGPA;
    applicant12Marks[msg.sender] = _applicant12Marks;
    scholarship.applicants.push(msg.sender);
    emit ApplicationSubmitted(_scholarshipId, msg.sender);
}

    function getApplicants(uint256 _scholarshipId) public view returns (address[] memory) {
        return scholarships[_scholarshipId].applicants;
    }

    function getScholarshipDetails(uint256 _scholarshipId) public view returns (ScholarshipDetail memory) {
        return scholarships[_scholarshipId];
    }

    function awardScholarship(uint256 _scholarshipId, address _student) public {
        require(msg.sender == admin, "Only admin can award scholarships");
        ScholarshipDetail storage scholarship = scholarships[_scholarshipId];
        require(scholarship.status == Status.Open, "Scholarship is not open for awarding");
        require(scholarship.awardedTo == address(0), "Scholarship already awarded");

        scholarship.awardedTo = _student;
        scholarship.status = Status.Awarded;
        emit ScholarshipAwarded(_scholarshipId, _student);
    }
}
