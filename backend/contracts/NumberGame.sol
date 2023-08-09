// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NumberGame {
    enum GameState {
        WaitingForPlayer,
        BothPlayerFinishBet,
        GameEnded
    }

    GameState public currentState;
    address payable public owner;
    address payable public player1;
    address payable public player2;
    uint256 public player1Bet;
    uint256 public player2Bet;
    uint256 public minimumBet;
    uint256 public defaultMinBet;
    uint256 private targetNumber;
    uint256 private player1Guess;
    uint256 private player2Guess;
    bool public p1BetStatus;
    bool public p2BetStatus;
    bool public gameEnded;
    address public currentPlayer;

    constructor(uint256 _defaultMinBet) payable {
        owner = payable(msg.sender);
        generateTargetNumber();
        defaultMinBet = _defaultMinBet;
    }

    function generateTargetNumber() private {
        require(
            msg.sender == owner ||
                msg.sender == player1 ||
                msg.sender == player2,
            "Only the owner can generate the target number"
        );
        targetNumber =
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % 10) +
            1;
    }

    function setMinimumBet(uint256 newMinimumBet) public {
        require(msg.sender == owner, "Only the owner can set the minimum bet");
        defaultMinBet = newMinimumBet;
        minimumBet = newMinimumBet;
    }

    function ownerWithdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(
            amount <= address(this).balance,
            "Amount is more than available balance"
        );
        require(
            currentState == GameState.GameEnded,
            "The game must be ended to withdraw"
        );
        owner.transfer(amount);
    }

    function changeOwner(address payable newOwner) public {
        require(msg.sender == owner, "Only the owner can change ownership");
        require(
            newOwner != address(0),
            "New owner address cannot be the zero address"
        );
        owner = newOwner;
    }

    function joinGame() public payable {
        require(
            player1 == address(0) || player2 == address(0),
            "Game is already full"
        );
        require(msg.sender != player1, "you have already joined the game");
        require(msg.sender != owner, "Owner cannot join the game");
        require(
            msg.value >= defaultMinBet,
            "Please send more ether to join the game"
        );

        if (player1 == address(0)) {
            player1 = payable(msg.sender);
            minimumBet = msg.value;
            player1Bet += msg.value;
            currentState = GameState.WaitingForPlayer;
        } else if (player2 == address(0)) {
            require(
                msg.value >= minimumBet,
                "The ether needed to join needs to be higher"
            );
            player2 = payable(msg.sender);
            player2Bet += msg.value;
        }
        gameEnded = false;
    }

    function makeGuess(uint256 guessNumber) public payable {
        require(
            currentState == GameState.WaitingForPlayer,
            "Both player have already bet"
        );
        require(
            guessNumber > 0 && guessNumber <= 10,
            "Guess must be between 1 and 10"
        );
        require(!gameEnded, "Game has already ended");
        require(msg.sender == player1 || msg.sender == player2, "Not a player");
        require(
            msg.value >= defaultMinBet,
            "Please send more ether to join the game"
        );
        require(
            msg.value >= minimumBet,
            "Please send ether with your guess equal or higher than the entry fee"
        );

        if (msg.sender == player1) {
            require(p1BetStatus == false, "You have Bet already");
            player1 = payable(msg.sender);
            player1Bet += msg.value;
            player1Guess = guessNumber;
            p1BetStatus = true;
        } else if (msg.sender == player2) {
            require(p2BetStatus == false, "You have Bet already");
            player2 = payable(msg.sender);
            player2Bet += msg.value;
            player2Guess = guessNumber;
            p2BetStatus = true;
        }

        if (p1BetStatus == true && p2BetStatus == true) {
            currentState = GameState.BothPlayerFinishBet;
        }

        if (currentState == GameState.BothPlayerFinishBet) {
            finalizeGame(player1Guess, player2Guess);
        }
    }

    function finalizeGame(uint256 p1Guess, uint256 p2Guess) public {
        require(!gameEnded, "Game has already ended");
        require(p1Guess > 0 && p1Guess <= 10, "Guess must be between 1 and 10");
        require(p2Guess > 0 && p2Guess <= 10, "Guess must be between 1 and 10");

        if (p1Guess == targetNumber && p2Guess == targetNumber) {
            gameEnded = true;
            uint256 totalBet = player1Bet + player2Bet;
            uint256 player1Share = (address(this).balance * player1Bet) /
                totalBet;
            uint256 player2Share = (address(this).balance * player2Bet) /
                totalBet;
            payable(player1).transfer(player1Share);
            payable(player2).transfer(player2Share);
            resetGame();
        } else if (p1Guess == targetNumber) {
            gameEnded = true;
            payable(player1).transfer(address(this).balance);
            resetGame();
        } else if (p2Guess == targetNumber) {
            gameEnded = true;
            payable(player2).transfer(address(this).balance);
            resetGame();
        } else {
            currentState = GameState.WaitingForPlayer;
            p1BetStatus = p2BetStatus = false;
        }
    }

    function withdraw() public {
        require(msg.sender == player1 || msg.sender == player2, "Not a player");

        if (msg.sender == player1) {
            require(p1BetStatus == false, "A guess is ongoing");
            uint256 amount = player1Bet / 2;
            require(amount >= minimumBet, "No balance to withdraw");
            payable(player1).transfer(amount);
            player1 = payable(address(0));
            player1Bet = 0;
        }
        if (msg.sender == player2) {
            require(p2BetStatus == false, "A guess is ongoing");
            uint256 amount = player2Bet / 2;
            require(amount >= minimumBet, "No balance to withdraw");
            payable(player2).transfer(amount);
            player2 = payable(address(0));
            player2Bet = 0;
        }
    }

    function setTargetNumber(uint256 newTargetNumber) public {
        require(
            newTargetNumber > 0 && newTargetNumber <= 10,
            "Guess must be between 1 and 10"
        );
        require(
            msg.sender == owner,
            "Only the owner can set the target number"
        );
        targetNumber = newTargetNumber;
    }

    function getTargetNumber() public view returns (uint256) {
        require(
            msg.sender == owner,
            "Only the owner can view the target number"
        );

        return targetNumber;
    }

    function resetGame() private {
        generateTargetNumber();
        player1 = payable(address(0));
        player2 = payable(address(0));
        p1BetStatus = p2BetStatus = false;
        player1Bet = player2Bet = 0;
        minimumBet = defaultMinBet;
        currentState = GameState.GameEnded;
    }
}
