SHELL := /bin/bash

DOCKER_NETWORK = docker network
NETWORK_NAME = kong-net
NETWORK_SUBNET = 10.0.30.0/24

export ENV=$(shell scripts/resolve_env.sh ENV)

export APP_PORT=$(shell scripts/resolve_env.sh APP_PORT)
export KONG_PROXY_LISTEN=$(shell scripts/resolve_env.sh KONG_PROXY_LISTEN)
export KONG_ADMIN_LISTEN=$(shell scripts/resolve_env.sh KONG_ADMIN_LISTEN)

export VERSION_TAG ?= $(shell git rev-parse --short HEAD)
export KONG_IMAGE_NAME = kong-api
export APP_IMAGE_NAME = test-app

export REPOSITORY_URL=$(shell scripts/resolve_env.sh REPOSITORY_URL)
export AWS_REGION=$(shell scripts/resolve_env.sh AWS_REGION)
export AWS_ACCESS_KEY_ID=$(shell scripts/resolve_env.sh AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(shell scripts/resolve_env.sh AWS_SECRET_ACCESS_KEY)
export AWS_SESSION_TOKEN=$(shell scripts/resolve_env.sh AWS_SESSION_TOKEN)

export STACK_NAME=${ENV}-ecs-ec2

export KONG_REPOSITORY_URL=${REPOSITORY_URL}:${KONG_IMAGE_NAME}-${VERSION_TAG}
export APP_REPOSITORY_URL=${REPOSITORY_URL}:${APP_IMAGE_NAME}-${VERSION_TAG}

ENVFILE ?= env/env.example
# creates/overwrites .env with $(ENVFILE)
envfile:
	cp -f $(ENVFILE) .env
.PHONY: envfile

container: kong_container app_container
.PHONY: container

tag: kong_container_tag app_container_tag
.PHONY: tag

publish: kong_publish app_publish
.PHONY: publish

infra: .env .network
	DEPLOY_STATE=present docker-compose run ansible_infra
.PHONY: infra

infra_shell: .env .network
	docker-compose run --entrypoint bash ansible_infra
.PHONY: infra_shell

infra_test: .env .network
	docker-compose run --entrypoint 'sh ./scripts/test_deploy.sh' infra
.PHONY: infra_test

infra_destroy: .env .network
	DEPLOY_STATE=absent docker-compose run ansible_infra
.PHONY: infra_destroy

container_test: .env .network app_run kong_run 
	sleep 5
	./scripts/test_containers.sh
.PHONY: container_test

kong_container: .env .network
	docker-compose build --build-arg ARG_PROXY_LISTEN=$(KONG_PROXY_LISTEN) --build-arg ARG_ADMIN_LISTEN=$(KONG_ADMIN_LISTEN) kongapi
.PHONY: kong_container

kong_container_tag:
	docker tag ${KONG_IMAGE_NAME}:${VERSION_TAG} ${KONG_REPOSITORY_URL}
.PHONY: kong_container_tag

kong_publish: .env .network
	REPOSITORY_URL=${KONG_REPOSITORY_URL} ./scripts/docker_push.sh 
.PHONY: kong_publish

kong_run: .env .network
	docker run -d -p $(KONG_PROXY_LISTEN):$(KONG_PROXY_LISTEN) -p $(KONG_ADMIN_LISTEN):$(KONG_ADMIN_LISTEN)  ${KONG_IMAGE_NAME}:${VERSION_TAG}
.PHONY: kong_run

app_container: .env .network
	docker-compose build --build-arg ARG_APP_PORT=$(APP_PORT) app
.PHONY: app_container

app_container_tag:
	docker tag ${APP_IMAGE_NAME}:${VERSION_TAG} ${APP_REPOSITORY_URL}
.PHONY: app_container_tag

app_publish: .env .network
	REPOSITORY_URL=${APP_REPOSITORY_URL} ./scripts/docker_push.sh
.PHONY: app_publish

app_run: .env .network
	docker run -d -p $(APP_PORT):$(APP_PORT) ${APP_IMAGE_NAME}:${VERSION_TAG}
.PHONY: app_run

#########
# Helpers
#########
.env:
	@echo "No .env file found. Please make envfile"
	exit 1

.network:
	$(DOCKER_NETWORK) inspect  $(NETWORK_NAME) > /dev/null 2>&1; \
	if [ $$? = "1" ]; then \
		echo "Setting up docker network"; \
		$(DOCKER_NETWORK) create --subnet $(NETWORK_SUBNET) --attachable $(NETWORK_NAME); \
		$(DOCKER_NETWORK) inspect  $(NETWORK_NAME) > /dev/null 2>&1; \
		[ $$? = "0" ]; \
	fi
.PHONY: .network