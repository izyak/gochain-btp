git restore data/single/genesis.json
# export KEYSTORE_DIR=$(pwd)/keystore/

# if [ ! -f KEYSTORE_DIR ]; then 
# 	mkdir keystore
# fi 

# cd keystore

# echo "Generating keystore files ..."
# addr1=$(goloop ks gen -o prep1.json | head -c 42)
# addr2=$(goloop ks gen -o prep2.json | head -c 42)
# addr3=$(goloop ks gen -o prep3.json | head -c 42)
# addr4=$(goloop ks gen -o prep4.json | head -c 42)
# echo "Keystores Generated ..."

# cd ..
python3 modify-genesis.py # $addr1 $addr2 $addr3 $addr4
