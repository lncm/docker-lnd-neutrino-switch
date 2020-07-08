# LND Neutrino Switch Contrainer

![Docker Pulls Count](https://img.shields.io/docker/pulls/lncm/neutrino-switcher.svg?style=flat)

## Clone directory

```bash
docker pull lncm/neutrino-switcher
```

## Files/Folders it needs access to

You may map these anywhere in your filesystem. For best results works best with a similar setup to [this one](https://github.com/lncm/thebox-compose-system)

- /secrets/rpcpass.txt (Bitcoin RPC Password)
- /lnd/lnd.conf (LND configuration. For best results write access please)
- /statuses/ (Write access for notifying of changes to other scripts for now)

## Environment Variables

Other than that everything should be in the default paths.

- JSONRPCURL (Default: http://10.254.2.2:8332) : Is the JSON-RPC interface for bitcoind
