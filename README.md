# MageSuite Docker Container For Running Magento Tests

[![](https://images.microbadger.com/badges/image/magesuite/run-tests:stable.svg)](https://microbadger.com/images/magesuite/run-tests:stable "Docker Image Badge") [![](https://images.microbadger.com/badges/version/magesuite/run-tests:stable.svg)](https://microbadger.com/images/magesuite/run-tests:stable "Docker Image Version Badge")


_Note: The `exec` mount opt on `/tmp` is needed for elasticsearch because it maps mem to temp files._

## Software

For now the `master` branch uses MySQL 5.6, Elasticsearch 6 and PHP 7.2.

Other versions will be avaialble on appropriately named branches / docker tags.

The image is big and there's not really a way around it since it has a lot of software and is based on CentOS (which we use for local dev / production deployments, so we want to keep everything else close).

## Basic usage

```bash
# Start the container with all services
docker run \
    --rm \
    --detach \
    --name mgs-test \
    --tmpfs /tmp:rw,exec \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /var/www/html/generated \
    --tmpfs /var/www/html/var \
    --tmpfs /dev/tests/integration/tmp \
    --volume "$(pwd):/var/www/html" \
    "magesuite/run-tests:stable"

# Wait until healthcheck is green
while [[ "$(docker inspect --format='{{json .State.Health.Status}}' mgs-test)" == '"starting"' ]] ; do sleep 1s && echo "Waiting for start"; done
    
# Then later execute your test suite
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
    --tmpfs /tmp:rw,exec \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /var/www/html/generated \
    --tmpfs /var/www/html/var \
    --tmpfs /dev/tests/integration/tmp \
    --volume "$(pwd):/var/www/html" \
    "magesuite/run-tests:stable" \
    "/usr/bin/elasticsearch-server" \
    "/usr/bin/mysql-server" \
    "/usr/bin/mgs-run-tests ci creativestyle $(id -u) $(id -g)"
```

## Run a bash shell without starting any services

```bash
docker run \
    --tty \
    --interactive \
    --tmpfs /tmp:rw,exec \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /var/www/html/generated \
    --tmpfs /var/www/html/var \
    --tmpfs /dev/tests/integration/tmp \
    --volume "$(pwd):/var/www/html" \
    "magesuite/run-tests:stable" \
    "/bin/bash"
```

You can start the services while inside by doing:

```bash
/usr/bin/elasticsearch-server &
/usr/bin/mysql-server &
```
