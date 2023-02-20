import json
# import sys

with open("./data/single/genesis.json") as file:
    data = json.load(file)


accounts = data.get('accounts')
accounts[2]['score']['contentId'] = "hash:{{hash:gov/governance-optimized.jar}}"

## if other wallets with balance required
# args = sys.argv[1:]
# for i,arg in enumerate(args):
#     obj = {'address': arg, 'balance': '0x2961fff8ca4a62327800000', 'name': f'wallet-{i}'}
#     accounts.append(obj)

data['accounts'] = accounts

# 0x15 : btp revision
data['chain']['revision'] = "0x15"

with open('./data/single/genesis.json', 'w') as f:
    json.dump(data, f, indent=2)