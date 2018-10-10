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

Following processes will be started:
* Postgres
* Redis
* `bin/guard` which runs tasks like RSpec when files are changed (see `Guardfile`)
* Rails server
* Sidekiq
* Logs output

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
