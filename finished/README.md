# Finished docker compose example

In case you're having trouble with the documentation, copy this `docker-compose.yaml` file to the root of the repo:

If you are using `fish` in the development container:

```text
cp (git rev-parse --show-toplevel)/finished/docker-compose.yaml (git rev-parse --show-toplevel)/docker-compose.yaml
```

Otherwise:

```sh
cp $(git rev-parse --show-toplevel)/finished/docker-compose.yaml $(git rev-parse --show-toplevel)/docker-compose.yaml
```
