#!/bin/bash -e

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Directories
# Allow access to /secrets/rpcpass.txt
# Allow access to LND directory (use /lnd/lnd.conf)
# Allow access to 'statuses'. /statuses/

# Output: /statuses/node-status-bitcoind-ready  (when ready, where a service can pick it up)


# if RPCPASS doesn't exist then set it (Default to whats in /secrets/rpcpass.txt)
if [ -z $RPCPASS ]; then
    RPCPASS=`cat /secrets/rpcpass.txt`
fi

# If JSONRPCURL doesn't exist then set it
if [ -z $JSONRPCURL ]; then
    JSONRPCURL="http://10.254.2.2:8332"
fi

# if LND_CONTAINER_NAME doesn't exist then set it
if [ -z $LND_CONTAINER_NAME ]; then
    LND_CONTAINER_NAME="lnd"
fi

while true; do
  IS_NEUTRINO=`grep -c 'bitcoin.node=neutrino' /lnd/lnd.conf`
  if [ $IS_NEUTRINO -eq 1 ]; then
    echo "If set to neutrino then lets check bitcoind"

    INFO=`curl --user lncm:$RPCPASS --data-binary '{"jsonrpc": "1.0", "id":"switchme", "method": "getblockchaininfo", "params": [] }' $JSONRPCURL 2>/dev/null`
    # check for errors
    ERROR=`echo $INFO | jq .error`
    if [ ! -z $ERROR ]; then
      # if no errors
      # Check prune mode
      PRUNE_MODE=`echo $INFO | jq .result.pruned`
      # check headers
      HEADERS=`echo $INFO | jq .result.headers`
      # check blocks
      BLOCKS=`echo $INFO | jq .result.blocks`

      if [ $PRUNE_MODE != "true" ]; then
        echo "Not pruned"
        # Node pruned so lets do the switching
        echo "Checking if synced...."
        if [ ! -f /statuses/node-status-bitcoind-ready ]; then
          if [ $HEADERS -eq $BLOCKS ]; then
              echo "Bitcoind has been switched across to neutrino"
              touch /statuses/node-status-bitcoind-ready
              sed -i 's/bitcoin.node\=neutrino/bitcoin.node\=bitcoind/g; ' /lnd/lnd.conf
              echo "Attempting to Restarting LND"
              if command -v docker &> /dev/null; then
                # restart docker
                docker stop $LND_CONTAINER_NAME
                docker start $LND_CONTAINER_NAME
              else
                echo "Docker command doesn't exist, reverting config"
                rm /statuses/node-status-bitcoind-ready
                sed -i 's/bitcoin.node\=bitcoind/bitcoin.node\=neutrino/g; ' /lnd/lnd.conf
              fi
          else
              echo "Node isn't full synched yet"
          fi
        else
            echo "LND is already switched to bitcoind!"
        fi
      else
        echo "No need to switch from neutrino in pruned mode"
      fi
    else
      # if bitcoind error
      echo "Error from bitcoind"
      echo $ERROR
    fi
  else
    echo "Neutrino mode has been disabled"
    echo "Switchback is not supported in this version"

    #TODO: Lets maybe try to switch back
  fi
  # Run every every 1 hour
  sleep 3600
done
