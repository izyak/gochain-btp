#!/bin/bash

export CONTRACTS=$HOME/my_work_bench/ibriz/btp-related/gochain-btp/contracts
export CONTRACT_HOME=$HOME/my_work_bench/ibriz/ibc-related/IBC-Integration/contracts/javascore
export WALLET=$HOME/keystore/godWallet.json
contractAddressFolder=./env/

CMD=$1
BRANCH=main

function moveIBC() {
	cd $CONTRACT_HOME

	git checkout $BRANCH
	./gradlew ibc:build -x test
	./gradlew ibc:optimizedJar
	cd ibc/build/libs
	mv ibc-0.1.0-optimized.jar $CONTRACTS 

	cd $CONTRACTS
	mv ibc-0.1.0-optimized.jar ibc-optimized.jar
}


function moveContracts() {
	cd $CONTRACT_HOME

	# for light client
	# git checkout feature/ICON-mock-lightclient
	git checkout $BRANCH
	./gradlew mockclient:build -x test
	./gradlew mockclient:optimizedJar
	cd lightclients/mockclient/build/libs
	mv mockclient-0.1.0-optimized.jar $CONTRACTS
	
	cd $CONTRACTS
	mv mockclient-0.1.0-optimized.jar client-optimized.jar

	# for ibc handler
	cd $CONTRACT_HOME
	git checkout $BRANCH
	./gradlew ibc:build -x test
	./gradlew ibc:optimizedJar
	cd ibc/build/libs
	mv ibc-0.1.0-optimized.jar $CONTRACTS 

	cd $CONTRACTS
	mv ibc-0.1.0-optimized.jar ibc-optimized.jar
}

function updateContract() {
	echo "Update IBCHandler---"
	export ENDPOINT=http://localhost:9082/api/v3
	local password=gochain
	local contractAddress=$1
	local contractFile=$2
	echo $contractAddress


	local txHash=$(goloop rpc sendtx deploy $contractFile \
			--content_type application/java \
			--uri $ENDPOINT  \
			--nid 3 \
			--step_limit 100000000000\
			--to  $contractAddress \
			--key_store $WALLET \
			--key_password $password | jq -r .)
	sleep 2
	txRes=$(goloop rpc txresult --uri $ENDPOINT $txHash)
	echo $txRes
}

function updateContractMock() {
	echo "Update IBCHandler---"
	export ENDPOINT=http://localhost:9082/api/v3
	local password=gochain
	local contractAddress=$1
	local contractFile=$2
	local ibcHandlerAddress=$3
	echo $contractAddress


	local txHash=$(goloop rpc sendtx deploy $contractFile \
			--content_type application/java \
			--uri $ENDPOINT  \
			--nid 3 \
			--step_limit 100000000000\
			--to  $contractAddress \
			--param ibcHandler=$ibcHandlerAddress \
			--key_store $WALLET \
			--key_password $password | jq -r .)
	sleep 2
	txRes=$(goloop rpc txresult --uri $ENDPOINT $txHash)
	echo $txRes
}

function updateIBCHandler() {
	cd $CONTRACT_HOME
	./gradlew ibc:build
	./gradlew ibc:optimizedJar
	cd ibc/build/libs
	mv ibc-0.1.0-optimized.jar $CONTRACTS 
	cd $CONTRACTS
	mv ibc-0.1.0-optimized.jar ibc-optimized.jar
	cd ..

	local ibcAddress1=$(cat $contractAddressFolder".ibcHandler")
	local ibcAddress2=$(cat $contractAddressFolder".ibcHandler2")

	updateContract $ibcAddress1 contracts/ibc-optimized.jar
	updateContract $ibcAddress2 contracts/ibc-optimized.jar
}

function updateMockApp(){
	local mockApp1=$(cat $contractAddressFolder".mockApp")
	local mockApp2=$(cat $contractAddressFolder".mockApp2")
	local ibcAddress1=$(cat $contractAddressFolder".ibcHandler")
	local ibcAddress2=$(cat $contractAddressFolder".ibcHandler2")


	cd $CONTRACT_HOME
	./gradlew mockapp:build
	./gradlew mockapp:optimizedJar
	cd modules/mockapp/build/libs
	mv mockapp-0.1.0-optimized.jar $CONTRACTS
	cd $CONTRACTS
	mv mockapp-0.1.0-optimized.jar mock-app-optimized.jar
	cd ..

	updateContractMock $mockApp1 contracts/mock-app-optimized.jar $ibcAddress1
	updateContractMock $mockApp2 contracts/mock-app-optimized.jar $ibcAddress2
}

case "$CMD" in
  move )
    moveContracts 
  ;;
  move-ibc )
    moveIBC
  ;;
  update )
    updateIBCHandler
  ;;

  update-mock )
	updateMockApp
  ;;
	
  * )
    echo "Error: unknown command: $CMD"
esac
