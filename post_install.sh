#!/bin/bash


export ENDPOINT=http://localhost:9082/api/v3
wallet=./data/godWallet.json
contractAddressFolder=./contract-filenames/
scoreAddressFilename=$contractAddressFolder"scoreAddr.env"
ibcAddressFilename=$contractAddressFolder"ibcAddr.env"
mockClientFilename=$contractAddressFolder"client.env"

#########Second contract Addrs
ibcAddressFilename2=$contractAddressFolder"ibcAddr2.env"
mockClientFilename2=$contractAddressFolder"client2.env"


###################Helpers##############

usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -eq 1 ]; then
    CMD=$1
else
    usage
fi


function printDebugTrace() {
	local txHash=$1
	goloop debug trace --uri http://localhost:9082/api/v3d $txHash | jq -r .
}

function wait_for_it() {
	local txHash=$1
	echo "Txn Hash: "$1
	
	status=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .status)
	if [ $status == "0x1" ]; then
    	echo "Successful"
    else
    	echo $status
    	read -p "Print debug trace? [y/N]: " proceed
    	if [[ $proceed == "y" ]]; then
    		printDebugTrace $txHash
    	fi
    	exit 0
    fi
}

i=0
function registerPRep() {
	((i++))
	wallet=$1
	password=gochain
	prep=$(cat $wallet | jq -r .address)

	echo "Registering" $prep "as prep"

	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --value 0x6c6b935b8bbd400000 \
	    --method registerPRep  \
	    --param name=Prep$i \
	    --param country=KOR \
	    --param city=Seoul \
	    --param email=prep-$i@icon.foundation \
	    --param website="https://www.google.com" \
	    --param details="https://www.google$i.com"\
	    --param p2pEndpoint=192.168.0.0:2321\
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function setRevision() {
	echo "Set revision"
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000001 \
	    --method setRevision  \
	    --param code=0x15 \
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function setStake() {
	echo "Set stake"
	local bond=0x2a5a058fc295ed000000
	local wallet=$1
	local password=gochain
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --method setStake  \
	    --param value=$bond \
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function setDelegation() {
	echo "Set delegation list"

	local password=gochain
	local prep=$(cat $wallet | jq -r .address)
    local param="{\"params\":{\"delegations\":[{\"address\":\"${prep}\",\"value\":\"0x152d02c7e14af6800000\"}]}}"

	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --method setDelegation  \
	    --raw $param \
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function setBonderList() {
	echo "Set bonder list"

	local password=gochain
	local prep=$(cat $wallet | jq -r .address)
	local param="{\"params\":{\"bonderList\":[\"${prep}\"]}}"

	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --method setBonderList  \
	    --raw $param \
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function setBond() {
	echo "Setting bond"
	local prep=$(cat $wallet | jq -r .address)
    local param="{\"params\":{\"bonds\":[{\"address\":\"${prep}\",\"value\":\"0x152d02c7e14af6800000\"}]}}"
	local password=gochain
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --method setBond  \
	    --raw $param \
	    --key_store $wallet \
	    --key_password $password | jq -r .)

	sleep 2
	wait_for_it $txHash
}

function registerPublicKey() {
	echo "Set node public key"

	local wallet=$1
	local pubKey=$2
	local password=gochain

	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000000 \
	    --method setPRepNodePublicKey \
	    --param pubKey=$pubKey \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	wait_for_it $txHash
}

# contract that can  send BTP Message
function deployBTPContract() {
	echo "Deploying a contract that can send BTPMessage"
	local wallet=$1
	local password=gochain

	local txHash=$(goloop rpc sendtx deploy btp-optimized.jar \
		--content_type application/java \
		--uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 100000000000\
	    --to cx0000000000000000000000000000000000000000 \
		--param name=BTP \
		--key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $scoreAddressFilename
}

function openBTPNetwork() {
	echo "Opening BTP Network of type eth"

	local wallet=$1
	local name=$2
	local owner=$3
	local password=gochain
	
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000001 \
	    --method iAmKing \
	    --param networkType=eth \
	    --param name=$name \
	    --param owner=$owner \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	wait_for_it $txHash
}

function setNetworkIdBTP() {
	echo "Setting Network Id"

	local wallet=$1
	local toContract=$2
	local password=gochain
	
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $toContract \
	    --method setNetworkId \
	    --param nid=0x1 \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	wait_for_it $txHash
}

function sendBTPMessage() {
	echo "Sending BTP Message---"

	local wallet=$1
	local toContract=$2
	local skipTxResult=$3
	local password=gochain
	
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $toContract \
	    --method sendPacket \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	echo $txHash

	if [[ $skipTxResult == "skip" ]]; then
    		return 
	fi


	sleep 2
	wait_for_it $txHash

	read -p "Print transaction result? [y/N]: " proceed
	if [[ $proceed == "y" ]]; then
		goloop rpc txresult --uri $ENDPOINT $txHash
	fi
}

function getPublicKey() {
	goloop rpc call --uri http://localhost:9082/api/v3 \
	    --to cx0000000000000000000000000000000000000000 \
	    --method getPRepNodePublicKey \
	    --param address=$(cat $1| jq -r .address)
}

function sendICX() {
	echo "Sending ICX---"

	local wallet=$1
	local to=$2
	local value=$3
	local skipTxResult=$4
	local password=gochain
	
	local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $to \
	    --value $3 \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	echo $txHash

	sleep 2
	wait_for_it $txHash

	read -p "Print transaction result? [y/N]: " proceed
	if [[ $proceed == "y" ]]; then
		goloop rpc txresult --uri $ENDPOINT $txHash
	fi
}

	
function deployIBCHandler() {
	echo "Deploy DeployIBCHandler---"
	local wallet=$1
	local filename=$2
	local password=gochain

	if [ -z "$filename" ]; then
		filename=$ibcAddressFilename
	fi

	local txHash=$(goloop rpc sendtx deploy contracts/ibc-optimized.jar \
			--content_type application/java \
			--uri $ENDPOINT  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx0000000000000000000000000000000000000000 \
			--key_store $wallet \
			--key_password $password | jq -r .)
	sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function deployMockClient() {
	echo "Deploy DeployMockClient---"
	local wallet=$1
	local password=gochain
	local filename=$2

	if [ -z "$mockClientFilename" ]; then
		filename=$mockClientFilename
	fi

	local txHash=$(goloop rpc sendtx deploy contracts/client-optimized.jar \
			--content_type application/java \
			--uri $ENDPOINT  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx0000000000000000000000000000000000000000 \
			--key_store $wallet \
			--key_password $password | jq -r .)
    sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ENDPOINT $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function registerMockClient() {
    echo "Register mock client---"
    local wallet=$1
    local password=gochain
    local toContract=$2
    local clientAddr=$3

    local txHash=$(goloop rpc sendtx call \
	    --uri $ENDPOINT  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $toContract\
	    --method registerClient \
	    --param clientType="07-tendermint" \
	    --param client=$clientAddr \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
    wait_for_it $txHash
}
     
function setupBTP(){

	echo "Run this after starting gochain-icon-image"
	echo "Starting after 5 seconds...."
	sleep 5

	registerPRep $wallet
	setStake $wallet
	setDelegation $wallet
	setBonderList $wallet
	setBond $wallet
	registerPublicKey $wallet 0x04b3d972e61b4e8bf796c00e84030d22414a94d1830be528586e921584daadf934f74bd4a93146e5c3d34dc3af0e6dbcfe842318e939f8cc467707d6f4295d57e5 # public key of godwallet

	## to get a BTP Block Height
	deployBTPContract $wallet
	openBTPNetwork $wallet eth $scoreAddr
	setNetworkIdBTP $wallet $scoreAddr
	sendBTPMessage $wallet $scoreAddr
}


function setupForIBC() {
    echo "Run this to start ibc configuration"
    echo "Starting in 3 seconds..."
    sleep 3

	local ibc=$1
	local mock=$2

	if [ -z "$ibc" ]; then 
		ibc=$ibcAddressFilename
	fi

	if [ -z "$mock" ]; then
		mock=$mockClientFilename
	fi


    deployIBCHandler $wallet $ibc
    echo "IBC Contract deployed at address:"
    local ibcHandler=$(cat $ibc)
    echo $ibc
	
    
    openBTPNetwork $wallet eth $ibcHandler

    deployMockClient $wallet $mock
    echo "Mock client deployed at address:"
    local mockClient=$(cat $mock)
    echo $mockClient   

    registerMockClient $wallet $ibcHandler $mockClient
}

function testMessage(){
	local scoreAddrFromF="$(cat $scoreAddressFilename)"
	sendBTPMessage $wallet $scoreAddrFromF
}

function multipleMessages() {
	echo $wallet 
	local scoreAddrFromF="$(cat $scoreAddressFilename)"

	sendBTPMessage $wallet $scoreAddrFromF skip
	sendBTPMessage $wallet $scoreAddrFromF skip
	sendBTPMessage $wallet $scoreAddrFromF skip
	sendBTPMessage $wallet $scoreAddrFromF skip
 }



##########Main switch case ###############
case "$CMD" in
  setup )
    setupBTP 
  ;;
  sendBTPMessage )
    testMessage
  ;;
  multipleBTPMessages )
    multipleMessages
  ;;
  deployIbcHandler )
		deployIBCHandler $wallet
  ;;
  deployMockClient )
		deployMockClient $wallet
  ;;
  ibcSetup )
	setupForIBC
  ;;
  ibcSetup-second )
	setupForIBC $ibcAddressFilename2 $mockClientFilename2
  ;;

  * )
    echo "Error: unknown command: $CMD"
    usage
esac

