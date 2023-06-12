#!/bin/sh

echo start rspec tests
docker-compose up -d

docker exec -it test_runner bash -c "sleep 10 && bundle install && bundle exec rspec $*"

