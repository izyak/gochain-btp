import  requests
import json

# data = {
#   "id": 1001,
#   "jsonrpc": "2.0",
#   "method": "icx_getLastBlock",
# }

data = {
  "id": 1001,
  "jsonrpc": "2.0",
  "method": "btp_getProof",
  "params": {
    "height": "0x11",
    "networkID" : "0x1"
  }
}

dump = json.dump(data)

URL = "https://ctz.solidwallet.io/api/v3"
resp = requests.get(URL, dump)
print(resp.data())
