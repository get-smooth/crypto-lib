#this script is meant to be run from solidity/

#configuration

#the way to sign the transactions to send, it is recommended to use a ledger dedicated to test and deployment 
#SIGNER="--ledger" #safe version, open Ethereum application on your ledger, allow blind signing
SIGNER="--private-key 0x80208c8c8030fa963691eec6c93ecb83c709791d675bb5a54f2609a18ca212d7"
#, unsafe version, using a private key of EOA
#PRIVATE_KEY
#opmainnet --chain-id 10 --rpc-url https://mainnet.optimism.io
#chain-id 137 --rpc-url https://polygon.llamarpc.com --sender 0x936632cC3B9BC47ad23D41dC7cc200015c447f71


#the public key related to your ledger/private key
SENDER=0x54669c319D656EcB1357F3D8D536449eedf5181C
#the script path to deploy
SCRIPT_PATH=script/Deploy7212.s.sol
SCRIPT_FUNCTION=:Script_Deploy_SCL

#TESTNETS
SEPOLIA_CHAINID=11155111
SEPOLIA_RPC=https://ethereum-sepolia.blockpi.network/v1/rpc/public

OP_TESNET_CHAINID=11155420
OP_TESTNET_RPC=https://optimism-sepolia.blockpi.network/v1/rpc/public

KKR_TESNET_CHAINID=1802203764
KKR_TESTNET_RPC=https://sepolia-rpc.kakarot.org/

ALL_RPC=($KKR_TESTNET_RPC  $OP_TESTNET_RPC)

ALL_TESTNETWORKS=("KAKAROT" "OP TESTNET")
#ALL_NETWORKS=("POLYGON MAINNET")
ALL_CHAINID=($KKR_TESNET_CHAINID $OP_TESNET_CHAINID)


#the api key for block explorer verification 
SEPOLIA_API_KEY=HURV4UYJZCCUTXEYM73M6J6CIJE1KN1W5X
OP_API_KEY=FV931ZWRMJCQWPHSJQ3KMPHI3CH48AFA7R

ALL_API_KEY=($SEPOLIA_API_KEY $OP_API_KEY)


echo "******************** BEGIN DEPLOYMENT OF PR:"$LAST_PR

#deploy and verify library on all networks, polygon need --legacy
for i in ${!ALL_TESTNETWORKS[@]}; do
  echo "Chain $i is ${ALL_NETWORKS[$i]} "
  echo "     ChainID: ${ALL_CHAINID[$i]}"
  CHAIN_ID="${ALL_CHAINID[$i]}"
  
  echo "     RPC: ${ALL_RPC[$i]}" 
  RPC="${ALL_RPC[$i]}"
  API_KEY=${ALL_API_KEY[$i]}
  
  #with verification
  ETHERSCAN_API_KEY=$API_KEY  forge script $SCRIPT_PATH$SCRIPT_FUNCTION  --broadcast --verify --chain-id $CHAIN_ID $SIGNER --rpc-url $RPC  --sender $SENDER 

  #without verification
  ETHERSCAN_API_KEY=$API_KEY  forge script $SCRIPT_PATH$SCRIPT_FUNCTION  --broadcast --verify --chain-id $CHAIN_ID $SIGNER --rpc-url $RPC  --sender $SENDER 

done
