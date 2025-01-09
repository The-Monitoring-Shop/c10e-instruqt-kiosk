#!/usr/bin/env bash

docker buildx build \
  --pull \
  --push \
  --platform=linux/amd64 \
  -t themonitoringshop/c10e-instruqt-kiosk:latest \
  -f Dockerfile . 
