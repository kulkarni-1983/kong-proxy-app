#!/bin/sh -eu

AWS_REGION="${AWS_REGION}"
REPOSITORY_URL="${REPOSITORY_URL}"

$(aws ecr get-login --region ${AWS_REGION} --no-include-email)	
docker push ${REPOSITORY_URL}