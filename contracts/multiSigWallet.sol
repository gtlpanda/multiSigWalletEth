// SPDX-License-Identifier: GPL-3.0

pragma solidity ;

contract multiSigWallet {
    
    // this is the transaction itself event aka how much we are sending, who is sending, and the balance
    event deposit(address indexed sender, uint amount, uint balance);
    
    // here we are going to design some info to be emiited when we call the functions
    event submitTransaction(
        address indexed owner, // the person calling the contractt
        uint indexed txIndex, // the indexed transaction 
        address indexed to, // who the fuck we are sending the transaction to
        uint value, // how much we are sending
        bytes data // dunno yet
        );
    event confirmTransaction(address indexed owner, uint indexed txIndex);
    event revokeTransaction(address indexed owner, uint indexed txIndex);
    event executeTransaction(address indexed owner, uint indexed txIndex);
    
    // store owners in the array of address aka owners of the wallet who can sign the transactions
    address[] public owners;
    mapping(address => bool) public isOwner; // checks if the address is an owner or not
    uint public numOfConfirmationsRequired;
    
    // when a transaction is proposed by one of the multisig owners, we will create a struct of the transaction here
    // then we are going to store the struct inside an array of transactions
    struct Transaction {
        address to;
        uint value;
        bytes data; // in the case we are calling another contract, we store the transaction data here
        bool executed; // we need to know if the transaction executed true false
        mapping(address => bool) isConfirmed; //when an owner approves the transaction, we will store that from a mapping to a boolean value I.E. true or false
        uint numConfirmations; // store number of approvals for the tx
    }
    Transaction[] public transactions;
    
    // the contructor will have the owners of the multisig wallet and the number of confirmations 
    constructor(address[] memory _owners, uint _numOfConfirmationsRequired) public {
        require(_owners.length > 0,'owners required');// input validation to make sure that owner array isnt empty
        require(
            _numOfConfirmationsRequired > 0 && _numOfConfirmationsRequired <= _owners.length, 
            'invalid number of required confirmations'
        );
        
        // we need to copy the owners from the owners array into the state variables
        for (uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),'invalid owner.');  // make sure owner is not equal to the zero address
            // we need to check that there are not any duplicate owners for line 24
            require(!isOwner[owner], 'owner not unique!'); // basically the mapping on line 24 returns a true or false.. 
            // here we are saying IF NOT TRUE AKA if not OWNER, we say no SIR 
            isOwner[owner] = true;
            owners.push(owner); // if the owner is the owner, we push the owner to the owners state variable 
        }
        numOfConfirmationsRequired = _numOfConfirmationsRequired; 
    }

    
    modifier onlyOwner() {
        require(isOwner[msg.sender], 'not owner');
        _;
    }
    // who is the transaction going to, whats the value, and what data is there to required to call another contract from 
    function submitTransaction(address to, uint value, bytes memory data) public onlyOwner {
        // we need the id of the transaction we are about to create 
        uint txIndex = transactions.length; // first trans will have 0, second will be 
        //push the transaction to the tranctions array by using the struct 
        // array name pushes struct 
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        
        emit submitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    
    // how do check if a transaction exist yet aka we check if the index for the transaction exists by checking if it 
    // is less than the array length of transactions
    // @param txIndex is the indexed transaction in the event we create called submitTransaction
    modifier txExist(uint _txIndex){
        require(_txIndex < transactions.length, 'transaction doesnt exist');
        _;
    }
    
    // get transaction at the index and make sure executed field is false 
    // @param txIndex is the indexed transaction in the event we create called submitTransaction
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, 'tx already executed');
        _;
    }
    
    // make sure transaction is already not confirmed by all owners 
    // @param   txIndex is the indexed transaction in the even we create called submitTransaction
    modifier notConfirmed(uint _txIndex){
        // we first by getting transaction at index and then we check the isConfirmed mapping is set to false
        require(!transactions[_txIndex].isConfirmed[msg.sender], 'tx already confirmed.');
        _;
    }
    

    // we only want owner to call this function
    // if trans exist, then it should not be executed yet
    function confirmTransaction(uint _txIndex) public
        onlyOwner
        txExist(_txIndex) 
        notExecuted(_txIndex) 
        notConfirmed(_txIndex) 
    {

        // get transaction at index
        Transaction storage transaction = transactions[_txIndex]; 
        transaction.isConfirmed[msg.sender] = true;
        transaction.numConfirmations +=1;
        
        emit confirmTransaction(msg.sender, _txIndex);
        
    }
    
    // @params txIndex will need to be passed 
    // @modifiers onlyOwner, txExists, and notExecuted are called
    function executeTransaction(uint _txIndex) public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex]; // get transaction at index and struct
        // make sure we have enough owner confirmations 
        require(
            transaction.numConfirmations >= numOfConfirmationsRequired, "cannot execute, not enough confirmations."
            );
        transaction.executed = true;
        
        // check if transaction was successful after owners confirmations
        (bool, success, ) = transaction.to.call.value(transaction.value)(transaction.data);
        require(success, "tx failed.");
        
        // emit the transation and the owner who called it
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    
    // @param   _txIndex is passed 
    // we check if the transaction has been executed yet with modifiers
    function revokeTransaction(uint _txIndex) public 
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    
    {
        // we need to get the transaction in order to deny or revoke it
        Transaction storage transaction = transactions[_txIndex];
        // make sure we have less required confirmations 
        require(transaction.numConfirmations < numOfConfirmationsRequired, "not enough owners denied confirmations for this transaction" );
        transaction.executed = false;
        
        // check if the transaction was revoked
        // if failed, that means the transaction went through
        (bool, failed, ) = transaction.to.call.value(transaction.value)(transaction.data);
        require(failed, "transaction was successful.");
        
        // emit the transaction and the owner to called it
        emit ExecuteTransaction(msg.sender, _txIndex);
        
    }
    
}
    
