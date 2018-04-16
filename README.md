# Gear Engine

Attempt to merge `straight` and `straight-server` gems into single Rails app.

## Hints

### Install dependencies

```bash
bin/setup
```

### Start development

```bash
devbox/start
``` 

### Build Docker image

```bash
bin/build
```

### Run Docker image

```bash
docker run --rm -it \
  -v $(realpath .env.production.sample):/gear-engine/.env.production \
  -p 19000:3000 gear-engine:latest bash -c 'bin/bundle exec bin/rails s'
```