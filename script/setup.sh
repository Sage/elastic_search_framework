#!/bin/sh

echo setup starting.....
docker-compose rm

echo build docker image
docker build --rm -t sage/elasticsearch_test_runner .

echo setup complete
