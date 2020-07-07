# LND Neutrino Switch Contrainer

![Docker Pulls Count](https://img.shields.io/docker/pulls/lncm/neutrino-switcher.svg?style=flat)


## Files/Folders it needs access to

You may map these anywhere in your filesystem

- /secrets/rpcpass.txt (Bitcoin RPC Password)
- /lnd/lnd.conf (LND configuration. For best results write access please)
- /statuses/ (Write access)

## Environment Variables

Other than that everything should be in the default paths.

- JSONRPCURL (Default: http://10.254.2.2:8332) : Is the JSON-RPC interface for bitcoind
