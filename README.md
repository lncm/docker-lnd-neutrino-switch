# LND Neutrino Switch Contrainer

![Docker Pulls Count](https://img.shields.io/docker/pulls/lncm/neutrino-switcher.svg?style=flat)

## Clone directory

```bash
docker pull lncm/neutrino-switcher
```

## If using docker-compose

- Container name of LND needs to match the environment variable defined (if not lnd)

## Files/Folders it needs access to

You may map these anywhere in your filesystem. For best results works best with a similar setup to [this one](https://github.com/lncm/thebox-compose-system)

- /secrets/rpcpass.txt (Bitcoin RPC Password)
- /lnd/lnd.conf (LND configuration. For best results write access please)
- /statuses/ (Write access)
- /var/run/docker.sock (is mapped correctly so it can restart the container)

## Environment Variables

Other than that everything should be in the default paths.

- JSONRPCURL (Default: http://10.254.2.2:8332) : Is the JSON-RPC interface for bitcoind
- LND_CONTAINER_NAME (Default: lnd) : is the container name to restart
