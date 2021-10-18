// SPDX-License-Identifier: GPL-3.0

pragma solidity <0.9.0;

contract multiSigWallet {
    // this is the transaction itself event aka how much we are sending, who is sending, and the balance
    event deposit(address indexed sender, uint256 amount, uint256 balance);

    // here we are going to design some info to be emiited when we call the functions
    event submitTransaction(
        address indexed owner, // the person calling the contractt
        uint256 indexed txIndex, // the indexed transaction
        address indexed to, // who the fuck we are sending the transaction to
        uint256 value, // how much we are sending
        bytes data // dunno yet
    );
    event confirmTransaction(address indexed owner, uint256 indexed txIndex);
    event revokeTransaction(address indexed owner, uint256 indexed txIndex);
    event executeTransaction(address indexed owner, uint256 indexed txIndex);

    // store owners in the array of address aka owners of the wallet who can sign the transactions
    address[] public owners;
    mapping(address => bool) public isOwner; // checks if the address is an owner or not
    uint256 public numOfConfirmationsRequired;

    // when a transaction is proposed by one of the multisig owners, we will create a struct of the transaction here
    // then we are going to store the struct inside an array of transactions
    struct Transaction {
        address to;
        uint256 value;
        bytes data; // in the case we are calling another contract, we store the transaction data here
        bool executed; // we need to know if the transaction executed true false
        mapping(address => bool) isConfirmed; //when an owner approves the transaction, we will store that from a mapping to a boolean value I.E. true or false
        uint256 numConfirmations; // store number of approvals for the tx
    }
    Transaction[] public transactions;

    // the contructor will have the owners of the multisig wallet and the number of confirmations
    constructor(address[] memory _owners, uint256 _numOfConfirmationsRequired)
        public
    {
        require(_owners.length > 0, "owners required"); // input validation to make sure that owner array isnt empty
        require(
            _numOfConfirmationsRequired > 0 &&
                _numOfConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        // we need to copy the owners from the owners array into the state variables
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner."); // make sure owner is not equal to the zero address
            // we need to check that there are not any duplicate owners for line 24
            require(!isOwner[owner], "owner not unique!"); // basically the mapping on line 24 returns a true or false..
            // here we are saying IF NOT TRUE AKA if not OWNER, we say no SIR
            isOwner[owner] = true;
            owners.push(owner); // if the owner is the owner, we push the owner to the owners state variable
        }
        numOfConfirmationsRequired = _numOfConfirmationsRequired;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // who is the transaction going to, whats the value, and what data is there to required to call another contract from
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        // we need the id of the transaction we are about to create
        uint256 txIndex = transactions.length; // first trans will have 0, second will be
        //push the transaction to the tranctions array by using the struct
        // array name pushes struct
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit submitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // how do check if a transaction exist yet aka we check if the index for the transaction exists by checking if it
    // is less than the array length of transactions
    // @param txIndex is the indexed transaction in the event we create called submitTransaction
    modifier txExist(uint256 _txIndex) {
        require(_txIndex < transactions.length, "transaction doesnt exist");
        _;
    }

    // get transaction at the index and make sure executed field is false
    // @param txIndex is the indexed transaction in the event we create called submitTransaction
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // make sure transaction is already not confirmed by all owners
    // @param   txIndex is the indexed transaction in the even we create called submitTransaction
    modifier notConfirmed(uint256 _txIndex) {
        // we first by getting transaction at index and then we check the isConfirmed mapping is set to false
        require(
            !transactions[_txIndex].isConfirmed[msg.sender],
            "tx already confirmed."
        );
        _;
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExist(_txIndex) // we only want owner to call this function
        notExecuted(_txIndex) // if trans exist, then it should not be executed yet
        notConfirmed(_txIndex) // make sure the trans is not confirmed yet
    {
        Transaction storage transaction = transaction[_txIndex]; // get transaction at index
        transaction.isConfirmed[msg.sender] = true;
        transaction.numConfirmations += 1;

        emit confirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction() {}

    function revokeTransaction() {}
}
