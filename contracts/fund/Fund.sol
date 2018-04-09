pragma solidity ^0.4.18;


import "../ownership/Ownable.sol";
import "./CryptoYenInterface.sol";


contract Fund is Ownable {
  event DebugEvent(uint256 indexed  _uint256, int256 indexed _int256, bool indexed _bool);
  int constant DECIMAL_MULTIPLIER = int(10**18);
  
  /* @dev Mintable utility token using for payments to beneficiary */
  CryptoYenInterface public cryptoYen;


  struct FundInitialState {
    int totalPriorityRights;
    int totalSubordinatedRights;
    int totalRights;
    int cashReserves;
    int priorityDividendsRate;
    int trustFeeRate;
    uint dividendsCalculationTermBeginnig;
    uint trustFeesCalculationTermBeginnig;
  }

  FundInitialState public fundTerms;

  struct FundState {
    int principalCollected;
    int interestCollected;
    int bankInterest;
    int expenses;
    int trustFees;
    int priorityPrincipal;
    int subordinatedPrincipal;
    int loansPrincipal;
    int dividendsNotDistributed;
    int principalNotDistributed;
    int reserveCash;
    uint lastDividendsCalculationDate;
    uint lastTrustFeesCalculationDate;
  }

  FundState[] public fundStates;




  /* 
    @dev beneficiary struct:
      - addr - ethereum address of beneficiary
      - amout - beneficiary rights
      - balance - current balance of investor
  */

  struct Beneficiary{
    int balance;
    int amount;
    int lastDividends;
    int lastRedemption;
  }

  mapping (address => Beneficiary) priorityBeneficiaries;
  mapping (address => Beneficiary) subordinatedBeneficiaries;

  address[] public priorities;
  address[] public subordinated;

  /* @dev bitmask of initialization progress. 0x1 - initData, 0x2 - initBeneficiary */
  uint8 public initializationProgress;


  function getStateLength() public view returns(uint) {
    return fundStates.length;
  }

  function getLastState() public view returns(int[]){
    FundState storage lastState = fundStates[fundStates.length - 1];
    int[] memory res = new int[](13);
    res[0] = lastState.principalCollected;
    res[1] = lastState.interestCollected;
    res[2] = lastState.bankInterest;
    res[3] = lastState.expenses;
    res[4] = lastState.trustFees;
    res[5] = lastState.priorityPrincipal;
    res[6] = lastState.subordinatedPrincipal;
    res[7] = lastState.loansPrincipal;
    res[8] = lastState.dividendsNotDistributed;
    res[9] = lastState.principalNotDistributed;
    res[10] = lastState.reserveCash;
    res[11] = int(lastState.lastDividendsCalculationDate);
    res[12] = int(lastState.lastTrustFeesCalculationDate);
    return res;
  }


  function getInitialTerm() public view returns(int[]){
    int[] memory res = new int[](8);
    res[0] = fundTerms.totalPriorityRights;
    res[1] = fundTerms.totalSubordinatedRights;
    res[2] = fundTerms.totalRights;
    res[3] = fundTerms.cashReserves;
    res[4] = fundTerms.priorityDividendsRate;
    res[5] = fundTerms.trustFeeRate;
    res[6] = int(fundTerms.dividendsCalculationTermBeginnig);
    res[7] = int(fundTerms.trustFeesCalculationTermBeginnig);
    return res;
  }


  /**
   * @dev Fund constructor
   */

  function Fund(address _cryptoYen) public {
    cryptoYen = CryptoYenInterface(_cryptoYen);
    fundStates.push(FundState(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
  }


  function initState() private returns(bool) {
    FundState storage firstState = fundStates[0];
    firstState.principalCollected = 0;
    firstState.interestCollected = 0;
    firstState.bankInterest = 0;
    firstState.priorityPrincipal = fundTerms.totalPriorityRights;
    firstState.subordinatedPrincipal = fundTerms.totalSubordinatedRights;
    firstState.loansPrincipal = fundTerms.totalRights;
    firstState.dividendsNotDistributed = 0;
    firstState.principalNotDistributed = 0;
    firstState.reserveCash = fundTerms.cashReserves;
    firstState.lastDividendsCalculationDate = fundTerms.dividendsCalculationTermBeginnig;
    firstState.lastTrustFeesCalculationDate = fundTerms.trustFeesCalculationTermBeginnig;
    return true;
  }

  /**
   * @dev Function to init Fund data
   * @param _details :
   * 0 * int cashReserves;
   * 1 * int priorityDividendsRate;
   * 2 * int trustFeeRate;
   * 3 * uint dividendsCalculationTermBeginnig;
   * 4 * uint trustFeesCalculationTermBeginnig;
   */

  function initData(int[5] _details) public onlyOwner returns(bool) {
    fundTerms.cashReserves = _details[0];
    fundTerms.priorityDividendsRate = _details[1];
    fundTerms.trustFeeRate = _details[2];
    fundTerms.dividendsCalculationTermBeginnig = uint(_details[3]);
    fundTerms.trustFeesCalculationTermBeginnig = uint(_details[4]);

    cryptoYen.mint(this, uint(fundTerms.cashReserves));  
    initializationProgress = initializationProgress | 0x1;
    if (initializationProgress == 3) 
      initState();
    return true; 
  }

  /**
   * @dev Function to init beneficiary rights
   */

  function initBeneficiary(int[] _priorityBeneficiaries, int[] _subordinatedBeneficiaries) public onlyOwner returns(bool) {
    require (_priorityBeneficiaries.length % 2 == 0);
    require (_subordinatedBeneficiaries.length % 2 == 0);
    uint i;

    priorities = new address[](_priorityBeneficiaries.length / 2);
    subordinated = new address[](_subordinatedBeneficiaries.length / 2);

    int _totalPriorityRights = 0;
    int _totalSubordinatedRights = 0;

    for (i = 0; i < _priorityBeneficiaries.length; i+=2){
      priorities[i/2] = address(_priorityBeneficiaries[i]);
      priorityBeneficiaries[address(_priorityBeneficiaries[i])] = Beneficiary(int(_priorityBeneficiaries[i+1]), int(_priorityBeneficiaries[i+1]), 0, 0);
      _totalPriorityRights += int(_priorityBeneficiaries[i+1]);
    }

    for (i=0; i < _subordinatedBeneficiaries.length; i+=2){
      subordinated[i/2] = address(_subordinatedBeneficiaries[i]);
      subordinatedBeneficiaries[address(_subordinatedBeneficiaries[i])] = Beneficiary(int(_subordinatedBeneficiaries[i+1]), int(_subordinatedBeneficiaries[i+1]), 0, 0);
      _totalSubordinatedRights += int(_subordinatedBeneficiaries[i+1]);
    }

    fundTerms.totalPriorityRights = _totalPriorityRights;
    fundTerms.totalSubordinatedRights = _totalSubordinatedRights;
    fundTerms.totalRights = _totalPriorityRights + _totalSubordinatedRights;

    initializationProgress = initializationProgress | 0x2;
    if (initializationProgress == 3) 
      initState();
    return true;
  }

 /**
   * @dev Function to obtain beneficiary rights
   * first col: 
   *  1 - priority beneficiaty
   *  2 - subordinated beneficiary
   * second col: ethereum address (160 bit hex uint)
   * third col: beneficiary rights (int256 with DECIMAL_MULTIPLIER)
   */


  function getRightsOfEachInvestor() public view returns(int[]){
    uint cols = 3;
    int[] memory res = new int[](cols * (priorities.length + subordinated.length));
    uint i = 0;

    for (i = 0; i < priorities.length; i++){
      res[i*cols] = 1;
      res[i*cols+1] = int(priorities[i]);
      res[i*cols+2] = priorityBeneficiaries[priorities[i]].amount;
    }
    
    for (i = 0; i < subordinated.length; i++){
      res[(priorities.length+i)*cols] = 2;
      res[(priorities.length+i)*cols+1] = int(subordinated[i]);
      res[(priorities.length+i)*cols+2] = subordinatedBeneficiaries[subordinated[i]].amount;
    }
    return res;
  }


  /**
   * @dev Function to obtain balance for each investor in 3 col table
   * first col: 
   *  1 - priority beneficiaty
   *  2 - subordinated beneficiary
   *  3 - Credits for automobile loan
   *  4 - Dividends reserving account
   *  5 - Prinvipal reserving account
   *  6 - Cash reserving account
   * second col: ethereum address (160 bit hex uint)
   * third col: current balance (int256 with DECIMAL_MULTIPLIER)
   */

  function getBalanceForEachInvestor() public view returns(int[]){
    FundState storage lastState = fundStates[fundStates.length - 1];
    uint cols = 5;
    int[] memory res = new int[](cols * (4 + priorities.length + subordinated.length));
    uint i = 0;

    for (i = 0; i < priorities.length; i++){
      res[i*cols] = 1;
      res[i*cols+1] = int(priorities[i]);
      res[i*cols+4] = priorityBeneficiaries[priorities[i]].balance;
      res[i*cols+2] = priorityBeneficiaries[priorities[i]].lastRedemption;
      res[i*cols+3] = priorityBeneficiaries[priorities[i]].lastDividends;
    }
    
    for (i = 0; i < subordinated.length; i++){
      res[(priorities.length+i)*cols] = 2;
      res[(priorities.length+i)*cols+1] = int(subordinated[i]);
      res[(priorities.length+i)*cols+4] = subordinatedBeneficiaries[subordinated[i]].balance;
      res[(priorities.length+i)*cols+2] = subordinatedBeneficiaries[subordinated[i]].lastRedemption;
      res[(priorities.length+i)*cols+3] = subordinatedBeneficiaries[subordinated[i]].lastDividends;
    }

    i=priorities.length+subordinated.length;
    
    res[i*cols] = 3;
    res[i*cols+4] = lastState.loansPrincipal;
    res[i*cols+5] = 4;
    res[i*cols+9] = lastState.dividendsNotDistributed;    
    res[i*cols+10] = 5;
    res[i*cols+14] = lastState.dividendsNotDistributed;
    res[i*cols+15] = 6;
    res[i*cols+19] = lastState.reserveCash;

    return res;
  }


/*
  @dev Function to obtain balance sheet table

Assets	
credits for automobile loans	8627140509
due from bank accounts	322917961
principal reserving account	304084959
divideds reserving account	5830870
cash reserving account	13000000
Net loss	0
total	8627140509
Liabilities	
Principal	8944225463
priority beneficiary rights	8030000000
subordinated  beneficiary rights	901225463
beneficiary rights of reserve cash	13000000
Net profit	5833002
total	8950058465
*/

  function getBalanceSheet() public view returns (int[]){
    FundState storage lastState = fundStates[fundStates.length - 1];
    FundState storage prevState = fundStates[fundStates.length > 2 ? fundStates.length - 2: 0];
    uint cols = 1;
    int[] memory res = new int[](cols*13);

    res[0] = lastState.loansPrincipal;

    int principalReservingAccount = lastState.principalCollected + lastState.principalNotDistributed;
    int dividendsReservingAccount = lastState.interestCollected - lastState.trustFees - lastState.expenses;
    int cashReservingAccount = lastState.reserveCash;

    res[1] = principalReservingAccount + dividendsReservingAccount + cashReservingAccount + lastState.bankInterest;
    res[2] = principalReservingAccount;
    res[3] = dividendsReservingAccount;
    res[4] = cashReservingAccount;
    res[5] = 0;
    res[6] = res[0] + res[1] - res[5];

    int priorityBeneficiaryRights = prevState.priorityPrincipal;
    int subordinatedBeneficiaryRights = prevState.subordinatedPrincipal;
    int beneficiaryRightsOfReserveCash = prevState.reserveCash;

    res[7] = priorityBeneficiaryRights + subordinatedBeneficiaryRights + beneficiaryRightsOfReserveCash;
    res[8] = priorityBeneficiaryRights;
    res[9] = subordinatedBeneficiaryRights;
    res[10] = beneficiaryRightsOfReserveCash;
    res[11] = dividendsReservingAccount + lastState.bankInterest; 
    res[12] = priorityBeneficiaryRights + subordinatedBeneficiaryRights + beneficiaryRightsOfReserveCash + dividendsReservingAccount + lastState.bankInterest;
    return res;
  }

  function daysBetweenTimestamps(uint t1, uint t2) private pure returns(uint) {
    return t2 / 86400 - t1 / 86400;
  }



   /**
   * @dev Function to set information from OBK system
   */

// 0 // date	9/6/2017		int
// 1 // Principal collected	304084959		decimal
// 2 // Interest collected	6174416		decimal
// 3 // # of full settlements	97		int
// 4 // Bank interest	2132		decimal
// 5 // Expenses	0		decimal
// 6 // Trigger	0		decimal


  function setInformationFromOBK(int[7] _details) public onlyOwner returns(bool) {
    uint i;
    for (i = 0; i < _details.length; i++) {
      require(_details[0] >= 0);
    }

    FundState storage lastState = fundStates[fundStates.length - 1];
    FundState memory newState;
    



    newState.reserveCash = lastState.reserveCash;
    newState.principalCollected = _details[1];
    newState.interestCollected = _details[2];
    newState.bankInterest = _details[4];
    newState.expenses = _details[5];
    newState.lastDividendsCalculationDate = uint(_details[0]);
    newState.lastTrustFeesCalculationDate = uint(_details[0]);


    int dividendsToDistribute = newState.interestCollected + newState.bankInterest - newState.expenses + lastState.dividendsNotDistributed;
    int principalToDistribute = newState.principalCollected + lastState.principalNotDistributed;


    int dividendsPriorities = lastState.priorityPrincipal*fundTerms.priorityDividendsRate*int(daysBetweenTimestamps(lastState.lastDividendsCalculationDate, newState.lastDividendsCalculationDate))/365/DECIMAL_MULTIPLIER;
    newState.trustFees = lastState.loansPrincipal*fundTerms.trustFeeRate*int(daysBetweenTimestamps(lastState.lastTrustFeesCalculationDate, newState.lastTrustFeesCalculationDate))/365/DECIMAL_MULTIPLIER;
    int dividendsSubordinated = dividendsToDistribute - dividendsPriorities - newState.trustFees;


    newState.dividendsNotDistributed = dividendsToDistribute - newState.trustFees;
    newState.principalNotDistributed = principalToDistribute;

    int dividendsDistributed;
    int principalDistributed;
    
    (dividendsDistributed, principalDistributed) = distributePriorities(dividendsPriorities, principalToDistribute);


    newState.dividendsNotDistributed -= dividendsDistributed;
    newState.principalNotDistributed -= principalDistributed;
    newState.priorityPrincipal = lastState.priorityPrincipal - principalDistributed;
    
    (dividendsDistributed, principalDistributed) = distributeSubordinated(dividendsSubordinated, principalToDistribute);

    newState.dividendsNotDistributed -= dividendsDistributed;
    newState.principalNotDistributed -= principalDistributed;
    newState.subordinatedPrincipal = lastState.subordinatedPrincipal - principalDistributed;

    newState.loansPrincipal = newState.subordinatedPrincipal + newState.priorityPrincipal;
    fundStates.push(newState);
    return true;
  }


  function distributePriorities(int dividendsPriorities, int principalToDistribute) private returns(int, int) {
    int dividendsDistributed;
    int principalDistributed;
    int dividendsToMint;
    int principalToMint;
    uint i;

    for (i = 0; i < priorities.length; i++){
      Beneficiary storage ben = priorityBeneficiaries[priorities[i]];
      dividendsToMint = dividendsPriorities*ben.amount/fundTerms.totalPriorityRights;
      principalToMint = principalToDistribute*ben.amount/fundTerms.totalRights;
      dividendsDistributed += dividendsToMint;
      principalDistributed += principalToMint;
      ben.balance -= principalToMint;
      cryptoYen.mint(priorities[i], uint(dividendsToMint));
      cryptoYen.mint(priorities[i], uint(principalToMint));
      ben.lastRedemption = principalToMint;
      ben.lastDividends = dividendsToMint;
    }
    return (dividendsDistributed, principalDistributed);
  }


  function distributeSubordinated(int dividendsSubordinated, int principalToDistribute) private returns(int, int) {
    int dividendsDistributed;
    int principalDistributed;
    int dividendsToMint;
    int principalToMint;
    uint i;

    for (i = 0; i < subordinated.length; i++){
      Beneficiary storage ben = subordinatedBeneficiaries[subordinated[i]];
      dividendsToMint = dividendsSubordinated*ben.amount/fundTerms.totalSubordinatedRights;
      principalToMint = principalToDistribute*ben.amount/fundTerms.totalRights;
      dividendsDistributed += dividendsToMint;
      principalDistributed += principalToMint;
      ben.balance -= principalToMint;
      cryptoYen.mint(subordinated[i], uint(dividendsToMint));
      cryptoYen.mint(subordinated[i], uint(principalToMint));
      ben.lastRedemption = principalToMint;
      ben.lastDividends = dividendsToMint;
    }

    return (dividendsDistributed, principalDistributed);
  }

}
