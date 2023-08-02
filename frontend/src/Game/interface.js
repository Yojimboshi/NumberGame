import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import Abijson from '../contractABI.json';

//css
import style from '../MainInterface.module.css';
const OWNER_ADDRESS = process.env.REACT_APP_OWNER_ADDRESS;
const CONTRACT_ADDRESS = "0x87728653fdec1fDbF4b914c87AECea58953ac7e8"; // address of the contract

// Main Functions
function App() {
  var userGuessInput = 0;
  const [defaultAccount, setDefaultAccount] = useState(null);
  const [contract, setContract] = useState(null);
  const [targetNumber, setTargetNumber] = useState(null);
  const [guessMessage, setguessMessage] = useState(null);
  const [showErrorMessage, setShowErrorMessage] = useState(false);

  var minimumBet = "";



//auto initialized needed to connect to wallet

useEffect(() => {
    const init = async () => {
      if (window.ethereum) {
      window.ethereum
        .request({ method: 'eth_requestAccounts' })
        .then(result => {
          accountChangeHandler(result[0]);
        })
        .catch(error => {
          console.error('Error connecting wallet:', error);
        });
        
      const tempProvider = new ethers.providers.Web3Provider(window.ethereum);
      const tempSigner = tempProvider.getSigner();
      const tempContract = new ethers.Contract(CONTRACT_ADDRESS, Abijson, tempSigner);

      setContract(tempContract);
    } else {
      console.error('MetaMask extension not found.');
    }
    };
    init();
    window.ethereum.on('accountsChanged', accounts => {
      setDefaultAccount(accounts[0]);
    });
    
  }, []);

  const accountChangeHandler = (newAccount) => {
    setDefaultAccount(newAccount);
  };

//passing value to smart contract
  async function JoinGame(){
    try{
        const InitialBet = document.getElementById('EntryBet');
        const valueToSend = ethers.utils.parseEther(InitialBet); 
    
        const tx = await contract.joinGame({ value: valueToSend, gasLimit: 100000 });// send the ethers and gas to the smart contract
        await tx.wait();
        
    } catch(error){
        alert(error);
    }
  }

  async function Guess(){
    try{
      const guessing = await contract
      .makeGuess(player1Guess, { from: defaultAccount, gasLimit: 100000})
      await guessing.wait();
      setguessMessage(`Next Player ${defaultAccount}`);
      }catch(error){
      alert(error);
      }
    
  }

  async function GetNumber(){
    if(defaultAccount === OWNER_ADDRESS){
      try{
        const Number = await contract.getTargetNumber({from: defaultAccount, gasLimit: 100000});
        setTargetNumber(Number.toString());
        setTimeout(() => setTargetNumber(""), 5000 );
      }catch(error){
        alert(error);
      }
    }else{
      setShowErrorMessage(true);
      setTimeout(() => setShowErrorMessage(false), 5000);
    }
    
  }

  async function Withdraw(){
    try{
      await contract.withdraw({from:defaultAccount, gasLimit: 100000});
    } catch(error){
      alert(error);
    }
  }


// UI PART
  
  const HandleFormSubmit = (event)=>{
    event.preventDefault();
    const InputBetElement = document.getElementById('BetValue');
    const intValue = parseInt(userGuessInput, 10);
    const tempbet = parseFloat(InputBetElement.value);
    if (isNaN(intValue) && isNaN(tempbet)) {
      alert('Please enter a valid number.');
    }

    if(tempbet< 0.00005){
      alert(`Please Bet more than the minimum bet amount${minimumBet}`);
    }

    if (intValue <= 1 && intValue >= 10){
      
    } 
    else {
      Guess();
    }
  }

  return (
    <div className={style.Container}>
      <div className={style.LeftColumn}>
        {defaultAccount && <h3> Address: {defaultAccount} </h3>}

        <div className={style.Join_Game_Button}> 
          <input
            type="text"
            id="EntryBet"
            name="EntryBet"
            placeholder='Enter your Entry Bet'
          />
          <button onClick={JoinGame}>Join Game</button>
          <input
            type="text"
            id="BetValue"
            name="BetValue"
            placeholder='Enter your Bet'
          />
          <input
            type="text"
            id="GuessValue"
            name="GuessValue"
            placeholder='Enter your Guessing Number'
          />
          <button onClick={HandleFormSubmit}>Guess</button>
          <button onClick={Withdraw}>Withdraw</button>
          <button onClick={GetNumber}>Get Number</button>
          {showErrorMessage && <p>You are not authorized to show the target number</p>}
          <p>Player Turn: {guessMessage}</p>
          <p>Random Number: {targetNumber}</p>
        </div>
      </div>
    </div>
  );
}

export default App;
