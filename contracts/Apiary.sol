pragma solidity ^0.4.24;

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/apps-shared-minime/contracts/ITokenController.sol";
import "@aragon/apps-finance/contracts/Finance.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/apps/AragonApp.sol";
import "bancor-contracts/solidity/contracts/converter/BancorFormula.sol";


contract Apiary is BancorFormula, ITokenController, AragonApp {
    using SafeMath for uint256;

    address public constant ETH = address(0);

    bytes32 public constant BUY_ROLE = keccak256('BUY_ROLE');
    bytes32 public constant SELL_ROLE = keccak256('SELL_ROLE');
    bytes32 public constant WITHDRAW_ROLE = keccak256('WITHDRAW_ROLE');
    bytes32 public constant UPDATE_TAP_ROLE = keccak256('UPDATE_TAP_ROLE');

    string private constant ERROR_ON_BUY_VALUE_MISMATCH = "APIARY_BUY_VALUE_MISMATCH";
    string private constant ERROR_ON_BUY_VALUE_ZERO = "APIARY_BUY_VALUE_ZERO";
    string private constant ERROR_ON_BUY_AMOUNT_ZERO = "APIARY_BUY_AMOUNT_ZERO";
    string private constant ERROR_ON_SELL_AMOUNT_ZERO = "APIARY_SELL_AMOUNT_ZERO";
    string private constant ERROR_ON_SELL_INSUFFICIENT_BALANCE = "APIARY_SELL_INSUFFICIENT_BALANCE";
    string private constant ERROR_ON_SELL_VALUE_ZERO = "APIARY_SELL_VALUE_ZERO";
    string private constant ERROR_ON_SELL_INSUFFICIENT_POOL = "APIARY_SELL_INSUFFICIENT_POOL";
    string private constant ERROR_ON_UPDATE_TAP_TAP_TOO_LOW = "APIARY_UPDATE_TAP_TAP_TOO_LOW";
    string private constant ERROR_ON_WITHDRAW_POOL_ZERO = "APIARY_WITHDRAW_POOL_ZERO";
    string private constant ERROR_PROXY_PAYMENT_WRONG_SENDER = "APIARY_PROXY_PAYMENT_WRONG_SENDER";
    string private constant ERROR_ON_TRANSFER_WRONG_SENDER = "APIARY_TRANSFER_WRONG_SENDER";

    MiniMeToken public token;
    Finance public finance;
    uint256 public tap;
    uint256 public vsupply;
    uint256 public vbalance;
    uint32 public cw; // represented in ppm, 1-1000000

    uint256 public pool;
    uint256 public lastWithdrawal;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Buy(address indexed to, uint256 pool, uint supply, uint256 amount, uint256 value);
    event Sell(address indexed from, uint256 pool, uint supply, uint256 amount, uint256 value);
    event UpdateTap(uint256 tap);
    event Withdraw(uint256 value);

    function initialize(MiniMeToken _token, Finance _finance, uint256 _tap, uint32 _cw, uint256 _vsupply, uint256 _vbalance) onlyInit public  {
        initialized();

        token    = _token;
        finance  = _finance;
        tap      = _tap;
        cw       = _cw;
        vsupply  = _vsupply;
        vbalance = _vbalance;

        lastWithdrawal = now;
    }

    /***** External methods *****/

    /*
    * @notice Buy `@tokenAmount(self.ETH(): address, _value)` worth of ABT
    * @param _value The amount of wei to buy tokens with
    */
    function buy(uint256 _value) external payable auth(BUY_ROLE) {
        require(_value == msg.value, ERROR_ON_BUY_VALUE_MISMATCH);
        require(msg.value > 0, ERROR_ON_BUY_VALUE_ZERO);
        uint256 amount = getBuy(msg.value);
        require(amount > 0, ERROR_ON_BUY_AMOUNT_ZERO);

        _buy(msg.sender, _value, amount);
    }

    /**
    * @notice Redeem `@tokenAmount(self.token(): address, _amount)`
    * @param _amount The amount of ABT to sell
    */
    function sell(uint256 _amount) external auth(SELL_ROLE) {
        require(_amount > 0, ERROR_ON_SELL_AMOUNT_ZERO);
        require(token.balanceOf(msg.sender) >= _amount, ERROR_ON_SELL_INSUFFICIENT_BALANCE);
        uint256 value = getSell(_amount);
        require(value > 0, ERROR_ON_SELL_VALUE_ZERO);
        require(value <= pool, ERROR_ON_SELL_INSUFFICIENT_POOL);

        _sell(msg.sender, _amount, value);
    }

    /**
    * @notice Update tap to `@tokenAmount(self.ETH(): address, _tap * 24 * 3600)` / day
    * @param _tap The new tap in wei / sec
    */
    function updateTap(uint256 _tap) external auth(UPDATE_TAP_ROLE) {
        require(_tap > tap, ERROR_ON_UPDATE_TAP_TAP_TOO_LOW);
        _updateTap(_tap);
    }

    /**
    * @notice Withdraw `@tokenAmount(self.ETH(): address, self.getWithdrawValue(): uint256)` from the reserve pool to the Vault
    */
    function withdraw() external auth(WITHDRAW_ROLE) {
        // see @vbuterin's post at https://ethresear.ch/t/explanation-of-daicos/465
        require(pool > 0, ERROR_ON_WITHDRAW_POOL_ZERO);

        _withdraw(getWithdrawValue());
    }

    /***** Public methods *****/

    function supply() public view isInitialized returns(uint256) {
        return token.totalSupply();
    }

    function getBuy(uint256 _amount) public view isInitialized returns(uint256) {
        return calculatePurchaseReturn(
            safeAdd(supply(), vsupply),
            safeAdd(pool, vbalance),
            cw,
            _amount);
    }

    function getSell(uint256 _amount) public view isInitialized returns(uint256) {
        return calculateSaleReturn(
            safeAdd(supply(), vsupply),
            safeAdd(pool, vbalance),
            cw,
            _amount);
    }

    /*
    * @notice Compute the maximum amount one can withdraw from reserve pool at current block
    * @return The maximum amount one can withdraw from reserve pool at current block
    */
    function getWithdrawValue() public view isInitialized returns (uint256 value) {
        uint256 max = (now.sub(lastWithdrawal)).mul(tap);
        max > pool ? value = pool : value = max;
    }

    /***** ITokenController methods *****/

    /*
    * @dev Notifies the controller about a token transfer allowing the controller to decide whether to allow it or react if desired (only callable from the token)
    * @param _from The origin of the transfer
    * @param _to The destination of the transfer
    * @param _amount The amount of the transfer
    * @return False if the controller does not authorize the transfer
    */
    function onTransfer(address _from, address _to, uint _amount) public isInitialized returns (bool) {
        require(msg.sender == address(token), ERROR_ON_TRANSFER_WRONG_SENDER);
        return true;
    }

    /**
    * @notice Called when ether is sent to the MiniMe Token contract
    * @return True if the ether is accepted, false for it to throw
    */
    function proxyPayment(address) public payable returns (bool) {
        // Sender check is required to avoid anyone sending ETH to the Token Manager through this method
        // Even though it is tested, solidity-coverage doesnt get it because
        // MiniMeToken is not instrumented and entire tx is reverted
        require(msg.sender == address(token), ERROR_PROXY_PAYMENT_WRONG_SENDER);
        return false;
    }

    /**
    * @dev Notifies the controller about an approval allowing the controller to react if desired
    * @return False if the controller does not authorize the approval
    */
    function onApprove(address, address, uint) public returns (bool) {
        return true;
    }

    /***** Internal methods *****/

    function _mint(address _to, uint256 _amount) internal {
        token.generateTokens(_to, _amount); // minime.generateTokens() never returns false
        emit Mint(_to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal {
        token.destroyTokens(_from, _amount); // minime.destroyTokens() never returns false, only reverts on failure
        emit Burn(_from, _amount);
    }

    function _buy(address _to, uint256 _value, uint256 _amount) internal {
      _mint(_to, _amount);
      pool = pool.add(_value);
      emit Buy(_to, pool, token.totalSupply(), _amount, _value);
    }

    function _sell(address _from, uint256 _amount, uint256 _value) internal {
      _burn(_from, _amount);
      pool = pool.sub(_value);
      msg.sender.transfer(_value);

      emit Sell(_from, pool, token.totalSupply(), _amount, _value);
    }

    function _updateTap(uint256 _tap) internal {
        tap = _tap;
        emit UpdateTap(_tap);
    }

    function _withdraw(uint256 _value) internal {
      pool = pool.sub(_value);
      finance.deposit.value(_value)(address(0), _value, 'Withdrawal from apiary pool');
      lastWithdrawal = now;
      emit Withdraw(_value);
    }
}
