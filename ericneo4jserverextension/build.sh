#!/bin/bash

# FIXME: Correct name!
# FIXME: Jenkins integration etc. etc.

export DOCKER_BUILDKIT=1 # Requires Docker > 18.09
ARM="armdocker.rnd.ericsson.se"
REPO_PATH="aia_snapshots"
IMAGE_NAME="ericneo4jserverextension"
IMAGE_TAG="0.0.1-1"

docker build . -t ${ARM}/${REPO_PATH}/${IMAGE_NAME}:${IMAGE_TAG}
docker tag ${ARM}/${REPO_PATH}/${IMAGE_NAME}:${IMAGE_TAG} ${ARM}/${REPO_PATH}/${IMAGE_NAME}:latest

