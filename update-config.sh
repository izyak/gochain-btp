#!/bin/bash

ENDPOINT=http://localhost:9082/api/v3

YAML_FILE=$HOME/.relayer/config/config.yaml
BACKUP_YAML_FILE=$HOME/.relayer/config/config_backup.yaml

contractAddressFolder=./env/
ibcAddressFilename=$contractAddressFolder".ibcHandler"
ibcAddressFilename2=$contractAddressFolder".ibcHandler2"

ibcHandler1=$(cat $ibcAddressFilename)
ibcHandler2=$(cat $ibcAddressFilename2)

startHeight1=$(goloop rpc --uri $ENDPOINT btpnetwork 0x2 | jq -r .startHeight)
startHeight2=$(goloop rpc --uri $ENDPOINT btpnetwork 0x3 | jq -r .startHeight)

height1Int=$(printf "%d" "$startHeight1")
height2Int=$(printf "%d" "$startHeight2")

h1=$((height1Int + 1))
h2=$((height2Int + 1))

# yq w -i $YAML_FILE 'chains.icon.value.ibc-handler-address' $ibcHandler2
# yq w -i $YAML_FILE 'chains.icon.value.start-btp-height' $h2

# yq w -i $YAML_FILE 'chains.icon-1.value.ibc-handler-address' $ibcHandler1
# yq w -i $YAML_FILE 'chains.icon-1.value.start-btp-height' $h1

# yq delete -i $YAML_FILE 'paths.icon-cosmoshub.src.client-id'
# yq delete -i $YAML_FILE 'paths.icon-cosmoshub.dst.client-id'

cp $YAML_FILE $BACKUP_YAML_FILE
rm $YAML_FILE

cat <<EOF >> $YAML_FILE
global:
  api-listen-addr: :5183
  timeout: 10s
  memo: ""
  light-cache-size: 20
chains:
  icon:
    type: icon
    value:
      key: icx
      chain-id: icon
      rpc-addr: http://localhost:9082/api/v3/
      timeout: 30s
      keystore: $HOME/keystore/godWallet.json
      password: gochain
      icon-network-id: 3
      btp-network-id: 3
      start-btp-height: $h2
      ibc-handler-address: $ibcHandler2
  icon-1:
    type: icon
    value:
      key: icx
      chain-id: iconx
      rpc-addr: http://localhost:9082/api/v3/
      timeout: 30s
      keystore: $HOME/keystore/godWallet.json
      password: gochain
      icon-network-id: 3
      btp-network-id: 2
      start-btp-height: $h1
      ibc-handler-address: $ibcHandler1
paths:
  icon-cosmoshub:
    src:
      chain-id: iconx
    dst:
      chain-id: icon
    src-channel-filter:
      rule: ""
      channel-list: []
EOF