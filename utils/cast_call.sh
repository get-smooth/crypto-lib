#list of RPCs
LINEA_TESTNET_RPC=https://rpc.goerli.linea.build
SEPOLIA_TESTNET_RPC=https://ethereum-sepolia.blockpi.network/v1/rpc/public
BASESCAN_TESTNET=https://goerli.base.org 

OP_TESTNET_RPC=https://optimism-sepolia.blockpi.network/v1/rpc/public

KKR_TESTNET_RPC=https://sepolia-rpc.kakarot.org/

FCL_ADDRESS=0xE9399D1183a5cf9E14B120875A616b6E2bcB840a   #This FCL available on Polygon, optimism, Sepolia, basescan and linea testnets
DAIMO_ADDRESS=0xc2b78104907F722DABAc4C69f826a522B2754De4 #Daimo is only testnet is basescan as of 25/10/23
VYPER_ADDRESS=0xD99D0f622506C2521cceb80B78CAeBE1798C7Ed5 #Vyper is available over sepolia
 
SCL7212_ADDRESS_KKR=0x0B6a5a1e1F7D1F93c9F8C54e60fa2a9d777d5298
#//optimism
SCL7212_ADDRESS_OP=0x2eFc48e84b8150008f3da85FF479a26036e68874
#cast call  0xEd0D252a3A26FB0269333BD6Cc720a8a68a68fcb "ecdsa_GenKeyPair()" --rpc-url https://ethereum-sepolia.blockpi.network/v1/rpc/public
#cast call  0xEd0D252a3A26FB0269333BD6Cc720a8a68a68fcb "ecdsa_GenKeyPair()" --rpc-url https://rpc.goerli.linea.build
#cast call  0xEd0D252a3A26FB0269333BD6Cc720a8a68a68fcb "ecdsa_GenKeyPair()" --rpc-url https://goerli.base.org 
#cast call  0xEd0D252a3A26FB0269333BD6Cc720a8a68a68fcb "ecdsa_GenKeyPair()" --rpc-url https://optimism-goerli.public.blastapi.io
#cast call  0xEd0D252a3A26FB0269333BD6Cc720a8a68a68fcb "ecdsa_GenKeyPair()" --rpc-url https://polygon.llamarpc.com

 
# pick a network and RPC
for iteration in 1 2
do
echo
RPC=$SEPOLIA_TESTNET_RPC
#pick a seed
SEED=$( echo $RANDOM)
#pick random values for input (testing purpose)
KPRIV=$(cast keccak "1"$SEED)
NONCE=$(cast keccak "2"$SEED)
MESSAGE=$(cast keccak "3"$SEED)

echo "seed:"$SEED

#derivate the public key value from private
KPUB=$(cast call $FCL_ADDRESS "ecdsa_DerivKpub(uint256)" $KPRIV --rpc-url $RPC)
Qx="0x"${KPUB:2:64}
Qy="0x"${KPUB:66:64}

echo "Kpub:"$Qx" "$Qy

#compute signature (r,s) of message with nonce and private key
SIG=$(cast call $FCL_ADDRESS "ecdsa_sign(bytes32, uint256, uint256)" $MESSAGE $NONCE $KPRIV --rpc-url $RPC)
r="0x"${SIG:2:64}
s="0x"${SIG:66:64}

echo "signature:"$SIG

echo "M:"$MESSAGE

echo "r:"$r
echo "s:"$s


#verify signature of message with public key
VERIF=$(cast call $FCL_ADDRESS "ecdsa_verify(bytes32, uint256, uint256, uint256, uint256)" $MESSAGE $r $s $Qx $Qy --rpc-url $RPC)
echo "*** verif with FCL:"$VERIF" with RPC="$RPC


RPC=$OP_TESTNET_RPC
#VERIF=$(cast call $SCL7212_ADDRESS_OP "ecdsa_verify(bytes32, uint256, uint256, uint256, uint256)" $MESSAGE $r $s $Qx $Qy --rpc-url $RPC)
#echo "*** verif with SCL on sepolia-optimism:"$VERIF" with RPC="$RPC

VERIF=$(cast call $SCL7212_ADDRESS_KKR "ecdsa_verify(bytes32, uint256, uint256, uint256, uint256)" $MESSAGE $r $s $Qx $Qy --rpc-url $KKR_TESTNET_RPC)
echo "*** verif with SCL on sepolia-kakarot:"$VERIF" with RPC="$KKR_TESTNET_RPC

cast code $SCL7212_ADDRESS_KKR --rpc-url $KKR_TESTNET_RPC
cast code $SCL7212_ADDRESS_OP --rpc-url $OP_TESTNET_RPC
cast code  --rpc-url $KKR_TESTNET_RPC


cast code 0x82aEB91015acE0db6073268d66DdA4AF3af4D050 --rpc-url https://optimism-sepolia.blockpi.network/v1/rpc/public
done

