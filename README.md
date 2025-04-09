
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mageops/docker-magento-run-tests/Publish%20docker%20container%20to%20docker%20hub)

# MageSuite Docker Container For Running Magento Tests

*Use `stable` or `-stable` suffixed docker tags (are built from `vX.Y` git tags), others may be unstable.*

Please see the GitHub Packages [mageops/magento-run-tests](https://github.com/mageops/docker-magento-run-tests/pkgs/container/magento-run-tests).

# Container timeout
Container will by default exit after 1h to prevent dangling container in CI environments,
you can adjust this behavior by changing setting different `CONTAINER_TIMEOUT` environment variable.
Setting `CONTAINER_TIMEOUT` to `no` will disable that behavior completely.

## Docker tags and software versions

The `master` branch uses Maria DB 10.2, Elasticsearch 6 and PHP 7.2 which are the latest versions supported by Magento.

Other versions will be avaialble on appropriately named branches / docker tags.

See [all tags](https://github.com/mageops/docker-magento-run-tests/pkgs/container/magento-run-tests/versions).

## Tag suffixes

- `-latest` - built from branch tip
- `-stable` - built from tags named `vX.Y`

## Plain tags

- `latest` - master branch tip
- `stable` - latest tag named `vX.Y`

## Notable versions
| Version | Docker tag | PHP | DB| Elasticsearch | Composer version | Phing version |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| **rl9-php80-es7-mysql80-phing2** | _rl9-php80-es7-mysql80-phing2-stable_ | 8.0.X | Mysql 8.0 | 7.17.3 | 2 | 2 |
| **rl9-php81-es7-mysql80-phing2** | _rl9-php81-es7-mysql80-phing2-stable_ | 8.1.X | Mysql 8.0 | 7.17.3 | 2 | 2 |
| **rl9-php82-es84-mysql80-phing2** | _rl9-php82-es84-mysql80-phing2-stable_ | 8.2.X | Mysql 8.0 | 8.4.3 | 2 | 2 |
| **rl9-php83-es811-mysql80-phing2** | _rl9-php83-es811-mysql80-phing2-stable_ | 8.3.X | Mysql 8.0 | 8.11.4 | 2 | 2 |
| **rl9-php84-es817-mysql84-phing2** | _rl9-php84-es817-mysql84-phing2-stable_ | 8.4.X | Mysql 8.4 | 8.17.4 | 2 | 2 |

_Note: The `exec` mount opt on `/tmp` is needed for elasticsearch because it maps mem to temp files._
_The image is big and there's not really a way around it since it has a lot of software and is based on RockyLinux (which we use for local dev / production deployments, so we want to keep everything else close)._

## Basic usage

### Start the container with all services

```bash
docker run \
    --rm \
    --detach \
    --name mgs-test \
    --tmpfs /tmp:rw,exec,mode=1777 \
    --tmpfs /var/lib/mysql:rw,mode=777 \
    --tmpfs /var/lib/elasticsearch:rw,mode=777 \
    --tmpfs /var/www/html/generated:rw,mode=777 \
    --tmpfs /var/www/html/var:rw,mode=777 \
    --tmpfs /var/www/html/dev/tests/integration/tmp:rw,mode=777 \
    --volume "$(pwd):/var/www/html" \
    "ghcr.io/mageops/magento-run-tests:php72-es6-mariadb102-stable"
```

### Wait until healthcheck is green

```bash
while [[ "$(docker inspect --format='{{json .State.Health.Status}}' mgs-test)" == '"starting"' ]] ; do sleep 1s && echo "Waiting for start"; done
```

### Then later execute your test suite

```bash
docker exec \
    --tty \
    mgs-test \
    /usr/bin/mgs-run-tests ci creativestyle "$(id -u)" "$(id -g)"
```

**_Alternatively_ if the internal UID/GID switch doesn't work for you for some reason you can try switching the docker UID/GID:**

```bash
docker exec \
    --tty \
    --user "$(id -u):$(id -g)" \
    mgs-test \
    /usr/bin/mgs-run-tests ci creativestyle
```

During the testing you can get into the bash shell to poke around:

```bash
docker exec -it mgs-test /bin/bash
```

## Run everthing at once

As an alternative you could run everything at once as the
tests will wait for healthcheck to become green before proceeding:

```bash
docker run \
    --tty \
    --tmpfs /tmp:rw,exec,mode=1777 \
    --tmpfs /var/lib/mysql:rw,mode=777 \
    --tmpfs /var/lib/elasticsearch:rw,mode=777 \
    --tmpfs /var/www/html/generated:rw,mode=777 \
    --tmpfs /var/www/html/var:rw,mode=777 \
    --tmpfs /var/www/html/dev/tests/integration/tmp:rw,mode=777 \
    --volume "$(pwd):/var/www/html" \
    "ghcr.io/mageops/magento-run-tests:php72-es6-mariadb102-stable" \
    "/usr/bin/elasticsearch-server" \
    "/usr/bin/mysql-server" \
    "/usr/bin/mgs-run-tests ci creativestyle $(id -u) $(id -g)"
```

## Run a bash shell without starting any services

```bash
docker run \
    --tty \
    --interactive \
    --tmpfs /tmp:rw,exec,mode=1777 \
    --tmpfs /var/lib/mysql:rw,mode=777 \
    --tmpfs /var/lib/elasticsearch:rw,mode=777 \
    --tmpfs /var/www/html/generated:rw,mode=777 \
    --tmpfs /var/www/html/var:rw,mode=777 \
    --tmpfs /var/www/html/dev/tests/integration/tmp:rw,mode=777 \
    --volume "$(pwd):/var/www/html" \
    "ghcr.io/mageops/magento-run-tests:php72-es6-mariadb102-stable" \
    "/bin/bash"
```

You can start the services while inside by doing:

```bash
/usr/sbin/start-elasticsearch &
/usr/sbin/start-mysql &
```
