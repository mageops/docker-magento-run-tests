# MagesSuite Docker Container For Running Magento Tests

_Note: The `exec` mount opt on `/tmp` is needed for elasticsearch because it maps mem to temp files._

## Basic usage

```bash
# Start the container with all services
docker run \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
    --volume $(pwd):/var/www/html \
    --user $(id -u):$(id -g) \
    --name mgs-test \
    magesuite/build:latest
    
# Then later execute your test suite
docker exec --tty mgs-test /usr/bin/mgs-run-tests
```

During the testing you can get into the bash shell to poke around:

```bash
docker exec --tty --interactive mgs-test /bin/bash
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
    --volume $(pwd):/var/www/html \
    --user $(id -u):$(id -g) \
    magesuite/build:latest \
    "/usr/bin/elasticsearch-server" \
    "/usr/bin/mysql-server" \
    "/usr/bin/mgs-run-tests"
```

## Run a bash shell without starting any services

```bash
docker run \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
    --volume $(pwd):/var/www/html \
    --user $(id -u):$(id -g) \
    --interactive \
    --tty \
    magesuite/build:latest \
    /bin/bash
```

You can start the services while inside by doing:

```bash
/usr/bin/elasticsearch-server &
/usr/bin/mysql-server &
```
