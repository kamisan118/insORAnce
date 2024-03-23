// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {AIOracleCallbackReceiver} from "./AIOracleCallbackReceiver.sol";
import {IAIOracle} from "./IAIOracle.sol";

contract InsORAnce is AIOracleCallbackReceiver {
    struct InsuranceTerm {
        uint256 premium;
        uint256 coverage;
        string term_description;
    }

    mapping(bytes32 => InsuranceTerm) public insuranceTerms;
    mapping(address => uint256) public balances;

    // Event definitions
    event InsuranceTermAdded(bytes32 termId, InsuranceTerm term);
    event InsurancePurchased(address insured, bytes32 termId);
    event InsuranceFunded(bytes32 termId, uint256 amount);
    event ClaimProcessed(bytes32 termId, bool approved);

    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {}
    
    // Function to add insurance terms
    function add_insurance_terms(bytes32 termId, InsuranceTerm memory term) public {
        insuranceTerms[termId] = term;
        emit InsuranceTermAdded(termId, term);
    }

    // Function to buy insurance
    function buy_insurance(bytes32 termId) public payable {
        require(msg.value == insuranceTerms[termId].premium, "Incorrect premium amount");
        balances[msg.sender] += msg.value;
        emit InsurancePurchased(msg.sender, termId);
    }

    // Function to fund an insurance term
    function fund_term(bytes32 termId) public payable {
        // Logic to fund the term
        emit InsuranceFunded(termId, msg.value);
    }

    // Called by zkAutomation to send a claim to the AI
    function aiClaim(bytes32 termId) external payable {
        // Logic to process claim
        bool approved = false; // Logic to determine if approved or not

        string prompt = insuranceTerms[termId].term_description;
        bytes memory input = bytes(prompt);
        aiOracle.requestCallback(
            1, input, address(this), this.OAOCallback.selector, AIORACLE_CALLBACK_GAS_LIMIT
        );

        emit ClaimProcessed(termId, approved);
    }
    
    // Callback function for AI decision
    function OAOCallback(
        uint256 modelId,
        bytes calldata input,
        bytes calldata output
    ) external onlyAIOracleCallback {
        string calldata intent = string(output);
        Operation memory op = resolve_result(intent);

        emit CallbackOperationResult(
            modelId,
            input,
            output,
            op.action,
            op.p0,
            op.p1,
            op.p2
        );
    }
    
}
