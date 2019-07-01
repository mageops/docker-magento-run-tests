# MageSuite Docker Container For Running Magento Tests

[![](https://images.microbadger.com/badges/image/magesuite/run-tests:stable.svg)](https://microbadger.com/images/magesuite/run-tests:stable "Docker Image Badge") [![](https://images.microbadger.com/badges/version/magesuite/run-tests:stable.svg)](https://microbadger.com/images/magesuite/run-tests:stable "Docker Image Version Badge")
[![](https://images.microbadger.com/badges/commit/magesuite/run-tests.svg)](https://microbadger.com/images/magesuite/run-tests "Docker Image Commit Badge")

_Note: The `exec` mount opt on `/tmp` is needed for elasticsearch because it maps mem to temp files._

## Software

For now the `master` branch uses MySQL 5.6, Elasticsearch 6 and PHP 7.2.

Other versions will be avaialble on appropriately named branches / docker tags.

## Basic usage

```bash
# Start the container with all services
docker run \
    --name mgs-test \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
    --volume "$(pwd):/var/www/html" \
    "magesuite/run-tests:stable"
    
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
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
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
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
    --volume "$(pwd):/var/www/html" \
    "magesuite/run-tests:stable" \
    "/bin/bash"
```

You can start the services while inside by doing:

```bash
/usr/bin/elasticsearch-server &
/usr/bin/mysql-server &
```
