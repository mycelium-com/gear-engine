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
  -v $(realpath config/straight/production):/gear-engine/config/straight/production \
  -p 3000:3000 gear-engine:latest bash -c 'bin/bundle exec bin/rails s'
```