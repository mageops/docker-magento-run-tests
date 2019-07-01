# MagesSuite Docker Container For Running Magento Tests

_Note: The `exec` mount opt on `/tmp` is needed for elasticsearch because it maps mem to temp files._

```bash
docker run \
    --tmpfs /var/lib/mysql \
    --tmpfs /var/lib/elasticsearch \
    --tmpfs /tmp:rw,exec \
    --volume $(pwd):/var/www/html \
    --user $(id -u):$(id -g) \
    --name mgs-test
    magesuite/build:latest
    
docker exec --tty mgs-test /usr/bin/mgs-run-tests
```

