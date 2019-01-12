pragma solidity 0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract Ownable {
    address public owner;
    mapping(address => bool) admins;

    event AdminAdded(address indexed newAdmin);
    event AdminDeleted(address indexed admin);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0));
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function delManager(address _admin) external onlyOwner {
        require(admins[_admin]);
        admins[_admin] = false;
        emit AdminDeleted(_admin);
    }


    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract BattleOfPlanets is Ownable {
    using SafeMath for uint;

    struct Game {
        uint256 bet;
        address initiator;
        address responder;
        bytes32 hash;
        address winner;
        string cards;
        bool exists;
    }

    mapping (uint256 => Game) public games;
    mapping(address => uint256[]) private ownedGames;
    uint private lastGameId;

    event NewGame(address indexed initiator, uint256 bet, uint256 gameId);
    event GameAccepted(address indexed responder, uint256 gameId);
    event GameFinalized(address indexed winner, uint256 gameId);


    constructor() public {}

    function createGame(bytes32 _hash) public payable {
        require(msg.value > 0);

        games[++lastGameId] = Game({
            bet : msg.value,
            initiator : msg.sender,
            responder : address(0),
            hash : _hash,
            winner : address(0),
            cards : '',
            exists: true
            });

        ownedGames[msg.sender].push(lastGameId);

        emit NewGame(msg.sender, msg.value, lastGameId);
    }


    function acceptGame(uint256 _gameId) public payable {
        require(games[_gameId].exists);
        require(games[_gameId].responder == address(0));
        require(msg.value == games[_gameId].bet);

        games[_gameId].responder = msg.sender;
        emit GameAccepted(msg.sender, _gameId);
    }


    function finalizeGame(uint256 _gameId, address _winner, string _cards) onlyAdmin public {
        require(games[_gameId].exists);
        require(games[_gameId].winner == address(0));
        require(_winner == games[_gameId].initiator || _winner == games[_gameId].responder);

        games[_gameId].winner = _winner;
        games[_gameId].cards = _cards;

        _winner.transfer(games[_gameId].bet.mul(2));

        emit GameFinalized(_winner, _gameId);
    }



    function ownerGamesCount(address _owner) external view returns (uint256) {
        return ownedGames[_owner].length;
    }


    function gamesOf(address _owner) external view returns (uint256[]) {
        return ownedGames[_owner];
    }
}
