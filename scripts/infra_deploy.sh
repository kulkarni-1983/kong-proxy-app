#!/bin/sh -eu

VPC_ID=$(aws ec2 describe-vpcs --filters "Name='tag:Name',Values=${VPC_NAME}" --query 'Vpcs[0].VpcId' | tr -d '"')

PUBLIC_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=public" --query 'Subnets[*].SubnetId' | tr -d '"[]')
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=private" --query 'Subnets[*].SubnetId' | tr -d '"[]')

aws cloudformation deploy --template-file ecs-ec2-kong-app.yml --stack-name ${STACK_NAME} --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --parameter-overrides \
  "Env=${ENV}" "DesiredCapacity=${DESIRED_CAPACITY}" "MaxSize=${MAX_CAPACITY}" \
  "KongImage=${KONG_REPOSITORY_URL}" "AppImage=${APP_REPOSITORY_URL}" \
  "PublicSubnetId=${PUBLIC_SUBNET_IDS}" "PrivateSubnetId=${PRIVATE_SUBNET_IDS}" "VpcId=${VPC_ID}"

aws cloudformation describe-stacks --stack-name ${STACK_NAME}

