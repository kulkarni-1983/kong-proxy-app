#!/bin/sh -eu

ENV="${ENV}"
DESIRED_CAPACITY="${DESIRED_CAPACITY}"
MAX_CAPACITY="${MAX_CAPACITY}"

VPC_ID
PUBLIC_SUBNET_IDS
PRIVATE_SUBNET_IDS


STACK_NAME="${ENV}-ecs-ec2"
aws cloudformation deploy --template-file ecs-ec2-kong-app.yml -stack-name ${STACK_NAME} --parameter-overrides \
  DesiredCapacity=${DESIRED_CAPACITY} MaxSize=${MAX_CAPACITY} \
  KongImage=${KONG_REPOSITORY_URL} AppImage=${APP_REPOSITORY_URL} \
  PublicSubnetId=${PUBLIC_SUBNET_IDS} PrivateSubnetId=${PRIVATE_SUBNET_IDS} VpcId=${VPC_ID} KeyName=""
