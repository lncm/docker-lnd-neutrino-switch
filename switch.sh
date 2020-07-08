#!/bin/sh -e

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
    RPCPASS="$(cat /secrets/rpcpass.txt)"
fi

# If sleeptime isn't set, set it to 3600 (1 hour)
if [ -z $SLEEPTIME ]; then
    SLEEPTIME=3600
fi

# If JSONRPCURL doesn't exist then set it
if [ -z "$JSONRPCURL" ]; then
    JSONRPCURL='http://10.254.2.2:8332'
fi

# if LND_CONTAINER_NAME doesn't exist then set it
if [ -z $LND_CONTAINER_NAME ]; then
    LND_CONTAINER_NAME="lnd"
fi

PREV_MATCH=

switch_on_sync_done() {
	# Node not pruned so lets do the switching
	echo 'Checking if synced...'
	if [ -f /statuses/node-status-bitcoind-ready ]; then
		echo 'LND is already switched to bitcoind!'
		return 1
	fi

	if ! grep -q 'bitcoin.node=neutrino' /lnd/lnd.conf; then
		echo 'Neutrino mode has been disabled'
		echo 'Switchback is not supported in this version'
		return 1
	fi

	echo 'If set to neutrino then lets check bitcoind'

	if ! INFO="$(curl --silent --user "lncm:$RPCPASS" --data-binary '{"jsonrpc": "1.0", "id":"switchme", "method": "getblockchaininfo", "params": [] }' $JSONRPCURL)"; then
		echo "Error: 'getblockchaininfo' request to bitcoind failed"
		return
	fi

	if err="$(jq -ner "${INFO:-{}} | .error")"; then
		echo 'Error: from bitcoind'
		echo "${err:-Unknown error}"
		return
	fi

	INFO="$(jq -ne "$INFO | .result")"

	# Check if pruned
	if jq -ne "$INFO | .pruned == true"; then
		echo 'No need to switch from neutrino in pruned mode'
		return 1
	fi
	echo 'Not pruned'

	if jq -ne "$INFO | .headers - .blocks > 10"; then
		echo "Node isn't full synced yet"
		PREV_MATCH=
		return
	fi

	if [ -z "$PREV_MATCH" ]; then
		PREV_MATCH="$(jq -ne "$INFO | .headers")"
		echo 'Sync seems complete!  Will switch on next check.'
		return
	fi

	# Skip switch, if headers number didn't change since last check
	#	(possible network issue).
	if jq -ne "$INFO | .headers == $PREV_MATCH"; then
		echo 'Skipping switch for now: headers seem stale'
		return
	fi

	echo 'Bitcoind has been switched across to neutrino'
	touch /statuses/node-status-bitcoind-ready
	sed -Ei 's|(bitcoin.node)=neutrino|\1=bitcoind|g' /lnd/lnd.conf
  
  echo "Restarting LND"
  docker stop $LND_CONTAINER_NAME
  docker start $LND_CONTAINER_NAME
}

while true; do
	if ! switch_on_sync_done; then
		echo 'Checking not necessary. Exiting.'
		break
	fi

	# Run every every 1 hour by default or as per configurable
	sleep $SLEEPTIME
done
