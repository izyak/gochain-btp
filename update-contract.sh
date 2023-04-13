#!/bin/bash

export CONTRACTS=/home/lilixac/gochain-btp/contracts
export HOME=/home/lilixac/ibriz/ibc/IBC-Integration/contracts/javascore
CMD=$1
BRANCH=IIBC-108-implement-tendermint-light-client

function moveIBC() {
	cd $HOME

	git checkout $BRANCH
	./gradlew ibc:build -x test
	./gradlew ibc:optimizedJar
	cd ibc/build/libs
	mv ibc-0.1.0-optimized.jar $CONTRACTS 

	cd $CONTRACTS
	mv ibc-0.1.0-optimized.jar ibc-optimized.jar
}


function moveContracts() {
	cd $HOME

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
	cd $HOME
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
	local wallet=/home/lilixac/gochain-btp/data/godWallet.json
	local password=gochain
	local ibcHandler=$(cat .ibchandlerAddr)
	echo $ibcHandler

	local txHash=$(goloop rpc sendtx deploy contracts/ibc-optimized.jar \
			--content_type application/java \
			--uri $ENDPOINT  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx500fd12f06076b5248b854da94eae0b27c658132 \
			--key_store $wallet \
			--key_password $password | jq -r .)
	sleep 2
	txRes=$(goloop rpc txresult --uri $ENDPOINT $txHash)
	echo $txRes
}

function updateIBCHandler() {
	cd $HOME
	./gradlew ibc:build
	./gradlew ibc:optimizedJar
	cd ibc/build/libs
	mv ibc-0.1.0-optimized.jar $CONTRACTS 
	cd $CONTRACTS
	mv ibc-0.1.0-optimized.jar ibc-optimized.jar
	cd ..
	updateContract
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
  * )
    echo "Error: unknown command: $CMD"
esac
