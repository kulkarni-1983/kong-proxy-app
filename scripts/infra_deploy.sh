#!/bin/sh -eu

ENV="${ENV}"
DESIRED_CAPACITY="${DESIRED_CAPACITY}"
MAX_CAPACITY="${MAX_CAPACITY}"
VPC_NAME=${VPC_NAME}

VPC_ID=$(aws ec2 describe-vpcs --filters "Name='tag:Name',Values=${VPC_NAME}" --query 'Vpcs[0].VpcId')


PUBLIC_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=public" --query 'Subnets[*].SubnetId')
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=private" --query 'Subnets[*].SubnetId')


STACK_NAME="${ENV}-ecs-ec2"
aws cloudformation deploy --template-file ecs-ec2-kong-app.yml -stack-name ${STACK_NAME} --parameter-overrides \
  DesiredCapacity=${DESIRED_CAPACITY} MaxSize=${MAX_CAPACITY} \
  KongImage=${KONG_REPOSITORY_URL} AppImage=${APP_REPOSITORY_URL} \
  PublicSubnetId=${PUBLIC_SUBNET_IDS} PrivateSubnetId=${PRIVATE_SUBNET_IDS} VpcId=${VPC_ID} KeyName=""
