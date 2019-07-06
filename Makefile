SHELL := /bin/bash

DOCKER_NETWORK = docker network
NETWORK_NAME = kong-net
NETWORK_SUBNET = 10.0.30.0/24

export ENV=$(shell scripts/resolve_env.sh ENV)
export VERSION_TAG ?= $(shell git rev-parse --short HEAD)
export KONG_IMAGE_NAME = kong-api
export APP_IMAGE_NAME = test-app

export APP_ECR_REPOSITORY_URL=$(shell scripts/resolve_env.sh APP_ECR_REPOSITORY_URL)
export AWS_REGION=$(shell scripts/resolve_env.sh AWS_REGION)
export AWS_ACCESS_KEY_ID=$(shell scripts/resolve_env.sh AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(shell scripts/resolve_env.sh AWS_SECRET_ACCESS_KEY)
export AWS_SESSION_TOKEN=$(shell scripts/resolve_env.sh AWS_SESSION_TOKEN)

export STACK_NAME=${ENV}-ecs-ec2

export KONG_REPOSITORY_URL=${APP_ECR_REPOSITORY_URL}:${KONG_IMAGE_NAME}-${VERSION_TAG}
export APP_REPOSITORY_URL=${APP_ECR_REPOSITORY_URL}:${APP_IMAGE_NAME}-${VERSION_TAG}


container: kong_container app_container
.PHONY: container

tag: kong_container_tag app_container_tag
.PHONY: tag

publish: kong_publish app_publish
.PHONY: publish

infra: .network
	docker-compose run infra

infra_shell: .network
	docker-compose run --entrypoint sh infra

infra_test: .network
	docker-compose run --entrypoint 'sh ./scripts/test_deploy.sh' infra

kong_container: .network
	docker-compose build kongapi
.PHONY: kong_container

kong_container_tag:
	docker tag ${KONG_IMAGE_NAME}:${VERSION_TAG} ${KONG_REPOSITORY_URL}
.PHONY: kong_container_tag

kong_publish: .network
	REPOSITORY_URL=${KONG_REPOSITORY_URL} ./scripts/docker_push.sh 
.PHONY: kong_publish

kong_run: .network
	docker-compose run -d -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8444:8444 kongapi
.PHONY: kong_run

app_container: .network
	docker-compose build app
.PHONY: app_container

app_container_tag:
	docker tag ${APP_IMAGE_NAME}:${VERSION_TAG} ${APP_REPOSITORY_URL}
.PHONY: app_container_tag

app_publish: .network
	REPOSITORY_URL=${APP_REPOSITORY_URL} ./scripts/docker_push.sh
.PHONY: app_publish

app_run: .network
	docker-compose run -d -p 8080:8080 app
.PHONY: app_run

.network:
	$(DOCKER_NETWORK) inspect  $(NETWORK_NAME) > /dev/null 2>&1; \
	if [ $$? = "1" ]; then \
		echo "Setting up docker network"; \
		$(DOCKER_NETWORK) create --subnet $(NETWORK_SUBNET) --attachable $(NETWORK_NAME); \
		$(DOCKER_NETWORK) inspect  $(NETWORK_NAME) > /dev/null 2>&1; \
		[ $$? = "0" ]; \
	fi
.PHONY: .network