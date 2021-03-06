# Gear Engine

## Deploy

### Staging

Push to the main branch.

### Production

Push `prd` tag in order to promote the latest staging image to production.

```bash
git tag -f prd HEAD
git push -f origin prd
```

## Hints

### Install dependencies

```bash
bin/setup
```

### Start development

```bash
devbox/start
```

Following processes will be started:
* Postgres
* Redis
* `bin/guard` which runs tasks like RSpec when files are changed (see `Guardfile`)
* Rails server
* Sidekiq
* Logs output

#### BIP70 payment requests

`devbox/bip70-cert` may be used to generate certificate and private key for testing. 

### Build production-ready Docker image

```bash
bin/build
```

### Run Docker image

```bash
docker run --rm -it \
  -v $(realpath .env.production.sample):/gear-engine/.env.production \
  -p 19000:3000 gear-engine:latest bash -c 'bin/bundle exec bin/rails s'
```
