pragma solidity ^0.5.0;

contract CrowdFunding{
	//Model an account
	struct Account {
		uint UId;
		string Name;
		uint TranCount;
		uint DefaultCount;
		uint Amount;
		uint Rating;
		string Comments;
		uint minRating;
		bool Status;
	}
	mapping(address => Account) public Accounts;
	//Model a transaction
	struct Transaction {
		uint TId;
		address Creditor;
		address[] Debtors;
		uint TAmount;
		uint StartDate;
		uint Maturity;
		uint InterestRate;
		bool Default;
		uint Compensation;
		uint CurrentTime;
	}

	mapping(uint => Transaction) public Transactions;

	//Add a new account
	uint public AccountCount = 0;
	uint public TranCount = 0;
	address[] public addressCount = new address[](100);
	uint[] public TranCountNum = new uint[](100);


	function addAccount (address _address, string memory _name) private {
		AccountCount ++;
		addressCount[AccountCount] = _address;
		Accounts[_address] = Account(AccountCount, _name, 0, 0, 10000, 5000, "test", 2000, false);
	}
	//Apply fund
	function applyFund (address _address, uint _amount) private{
		//Function called address should be the same as Creditor Address
		require(_address == msg.sender);

		//Applying amount should be lower than maximum
		require(_amount <= 2000 * 2.72 ^ (Accounts[_address].Rating/1000) && _amount > 0);

		//One account can only have one transaction at the same time
		require(Accounts[_address].Status == false);
		//Go through all the current account
		// address[] memory Debtors = new address[](100);
		uint IR = Accounts[_address].Rating + 274000;
		//Initialize the transaction info
		TranCount ++;
		Transactions[TranCount] = Transaction(TranCount, _address, new address[](100), _amount, now, 12, IR, true, 1000, 1);
		TranCountNum.push(TranCount);
		//Find out the number of suitable debtors
		Transactions[TranCount].Debtors.push(address(0x519209ef10A46cC8234E0199a440635D3Fba0d26));
		uint t = 0;
		// Transactions[TranCount].Debtors = new address[](100);
		for (uint i = 1; i <= AccountCount; i++) {

			if (Accounts[addressCount[i]].minRating <= Accounts[_address].Rating && Accounts[addressCount[i]].Amount >= _amount){
				t ++;
				//Transactions[TranCount].Debtors.push(addressCount[i]);
				Accounts[addressCount[i]].Amount = Accounts[addressCount[i]].Amount - _amount;
				Accounts[_address].Amount = Accounts[_address].Amount + _amount;
			}
		}
		uint Allamount = _amount * t;
		//uint eachDebt = _amount / t;
		//Add the value
		//for (uint i = 1; i < AccountCount; i++) {
		//	if (Accounts[addressCount[i]].minRating <= Accounts[_address].Rating ){
		//		Accounts[addressCount[i]].Amount = Accounts[addressCount[i]].Amount - eachDebt;
		//		Accounts[_address].Amount = Accounts[_address].Amount + eachDebt;
		//	}
		//}
		//Change the account status
		Transactions[TranCount].TAmount = Allamount;
		Accounts[_address].Status = true;
		
		
	}

	//Update accounts information
	function updateAccounts () private {
		//Update Trancount and DefaultCount
		for (uint i = 0 ; i < TranCountNum.length; i++){
			Accounts[Transactions[TranCountNum[i]].Creditor].TranCount ++;
			if (Transactions[TranCountNum[i]].Default == true){
				Accounts[Transactions[TranCountNum[i]].Creditor].DefaultCount ++;
			}
		}
		//Update Rating
		for (uint i = 0; i < addressCount.length; i++){
			Accounts[addressCount[i]].Rating = 2000 - (1000 * Accounts[Transactions[TranCountNum[i]].Creditor].DefaultCount);
			// + Accounts[Transactions[TranCountNum[i]].Creditor].TranCount;
		}

	}
	//Pay back money
	function Payback() private {
		//Acount should be in a transaction now
		require(Accounts[msg.sender].Status == true);
		//Find out the particular transaction
		uint TransactionID;
		for (uint i = 0 ; i < TranCountNum.length; i++){
			if (Transactions[TranCountNum[i]].Creditor == msg.sender){
				TransactionID = TranCountNum[i];
				break;
			}
		}
		uint TAmount = Transactions[TransactionID].TAmount;
		uint MonthlyInterest = Transactions[TransactionID].TAmount * Transactions[TransactionID].InterestRate/1000000;
		//uint IR = Transactions[TransactionID].InterestRate;
		//ParValue = TAmount * ((1 + (100+IR)/100) ^ Maturity);
		//Calculate the coupon and par value
		//Make decision if it's in the maturity or on par
		if (Transactions[TransactionID].CurrentTime < 12){
			if (Accounts[msg.sender].Amount < MonthlyInterest){
				Transactions[TransactionID].Default = true;
			//Compensation
			}
			else {
			Accounts[msg.sender].Amount = Accounts[msg.sender].Amount - MonthlyInterest;
				for (uint i = 0; i < Transactions[TransactionID].Debtors.length; i++){
				Accounts[Transactions[TransactionID].Debtors[i]].Amount = Accounts[Transactions[TransactionID].Debtors[i]].Amount + MonthlyInterest/Transactions[TransactionID].Debtors.length;
				}
			//Miss the deadline -- Default but still payback
				if (now > Transactions[TransactionID].StartDate + Transactions[TransactionID].CurrentTime * 1 minutes){
				Transactions[TransactionID].Default = true;
				//compensation
				}
				else {
				Transactions[TransactionID].Default = false;
				}
			}
			Transactions[TransactionID].CurrentTime = Transactions[TransactionID].CurrentTime + 1;

		}
		else if (Transactions[TransactionID].CurrentTime == 12) {
			if (Accounts[msg.sender].Amount < TAmount + MonthlyInterest){
				Transactions[TransactionID].Default = true;
			//Compensation
			}
			else {
			Accounts[msg.sender].Amount = Accounts[msg.sender].Amount - MonthlyInterest - TAmount;
				for (uint i = 0; i < Transactions[TransactionID].Debtors.length; i++){
				Accounts[Transactions[TransactionID].Debtors[i]].Amount = Accounts[Transactions[TransactionID].Debtors[i]].Amount + (MonthlyInterest+TAmount)/Transactions[TransactionID].Debtors.length;
				}
			//Miss the deadline -- Default but still payback
				if (now > Transactions[TransactionID].StartDate + Transactions[TransactionID].CurrentTime * 1 minutes){
				Transactions[TransactionID].Default = true;
				//compensation
				}
				else {
				Transactions[TransactionID].Default = false;
				}
			}
			Transactions[TransactionID].CurrentTime = 1;
		}
		//Payback money
		//No enough money -- Default
		//if (Accounts[msg.sender].Amount < ParValue){
		//	Transactions[TransactionID].Default = true;
		//	//Compensation
		//}
		//else {
		//	Accounts[msg.sender].Amount = Accounts[msg.sender].Amount - ParValue;
		//	for (uint i = 0; i < Transactions[TransactionID].Debtors.length; i++){
		//		Accounts[Transactions[TransactionID].Debtors[i]].Amount = Accounts[Transactions[TransactionID].Debtors[i]].Amount + ParValue/Transactions[TransactionID].Debtors.length;
		//	}
		//	//Miss the deadline -- Default but still payback
		//	if (now > Transactions[TransactionID].StartDate + Maturity * 1 minutes){
		//		Transactions[TransactionID].Default = true;
		//		//compensation
		//	}
		//	else {
		//		Transactions[TransactionID].Default = false;
		//	}
		//}
	}
	
	constructor() public {
		//addAccount("Account 1");
		//addAccount("Account 2");
		addAccount(address(0xE701309D31FfBA4B80eE1FE90fC4864b41ac42Cb), 'Account A');
		addAccount(address(0x519209ef10A46cC8234E0199a440635D3Fba0d26), 'Account B');
		// applyFund(address(0xE701309D31FfBA4B80eE1FE90fC4864b41ac42Cb), 100);
		updateAccounts();
		// Payback();
		//addAccount(0xaef0B7Edd5D2E9315027ADFA4642E16a5c85Afd8, 'Account C');
		
	}
}