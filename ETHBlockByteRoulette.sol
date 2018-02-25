pragma solidity ^0.4.14;

contract ETHBlockByteRoulette {
    bytes32 public name = 'ETHBlockByteRoulette';
    address public owner;
    uint256 public max_fee;
    uint256 public create_block;
    uint256 public min_risk;
    uint8 public last_result;
    bytes1 private block_pointer;
    bytes1 private byte_pointer;
    mapping(uint8 => bool) private numbers;

    event Balance(uint256 _balance);
    event Play(address indexed _sender, bytes1[] _numbers, uint8 _result, bool _winner, uint256 _time);
    event Withdraw(address indexed _sender, uint256 _amount, uint256 _time);
    event Risk(uint256 _risk);
    event Destroy();

    function ETHBlockByteRoulette() public payable {
        owner = msg.sender;
        create_block = block.number; 
        block_pointer = 0xff;
        min_risk = 18;
        max_fee = msg.value / 4;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isPaid() {
        require(msg.value > 0 && msg.value <= max_fee);
        _;
    }

    modifier isDirect() {
        require(tx.origin == msg.sender);
        _;
    }

    function play(bytes1[] _numbers) public payable isDirect isPaid returns (bool) {
        // min risk is 18 now
        if (_numbers.length > min_risk) {
            revert();
        }
        // cast numbers to uint8 inside the map
        for (uint8 i = 0; i < _numbers.length; i++) {
            uint8 number = uint8(_numbers[i]);
            if (number == 0 || number > 36) {
                revert();
            }
            numbers[number] = true;
        }
        // get result block hash
        bytes32 block_hash = block.blockhash(block.number - uint8(block_pointer));
        // get result block byte
        bytes1 byte_result = block_hash[uint8(byte_pointer) % 32];
        // set new pointers for new play
        block_pointer = block_hash[31];
        if (block_pointer == 0x00) {
            block_pointer = 0xff;
        }
        byte_pointer = block_hash[0];

        // cast result to uint8
        last_result = uint8(byte_result);
        // calculate roulete result with 13% house
        uint8 roulette_result = 0;
        if (last_result < 221) {
            roulette_result = last_result % 37;
        }

        bool winner = false;
        // check for winner, ZERO is HOUSE
        if (numbers[roulette_result]) {
            winner = true;
            // there is a winner, calculate prize
            uint256 percentage_risk = 100 - (_numbers.length * 100) / 36;
            uint256 risk = min_risk * 100 / 36;
            uint256 percentage = ((percentage_risk - risk) * 100) / (100 - risk);

            uint256 prize = msg.value * percentage / 100;
            uint256 credit = msg.value + prize;
            if (!msg.sender.send(credit)) {
                revert();
            }
        }
        for (i = 0; i < _numbers.length; i++) {
            number = uint8(_numbers[i]);
            numbers[number] = false;
        }
        max_fee = this.balance / 4;
        Balance(this.balance);
        Play(msg.sender, _numbers, last_result, winner, now);
        return true;
    }

    function withdraw(uint256 _credit) public isOwner returns (bool) {
        if (!owner.send(_credit)) {
            revert();
        }
        Withdraw(msg.sender, _credit, now);
        max_fee = this.balance / 4;
        return true;
    }

    function risk(uint256 _min_risk) public isOwner returns (bool) {
        min_risk = _min_risk;
        Risk(min_risk);
        return true;
    }

    function destruct() public isOwner {
        Destroy();
        selfdestruct(owner);
    }

    function () public payable {
        max_fee = this.balance / 4;
        Balance(this.balance);
    }
}
