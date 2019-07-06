#!/bin/sh -eu


VPC_ID=$(aws ec2 describe-vpcs --filters "Name='tag:Name',Values=${VPC_NAME}" --query 'Vpcs[0].VpcId' | tr -d '"')


PUBLIC_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=public" --query 'Subnets[*].SubnetId' | tr -d '"[]')
PRIVATE_SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-003e06e33a87c22f5" "Name=tag:Tier, Values=private" --query 'Subnets[*].SubnetId' | tr -d '"[]')

echo $VPC_ID
echo $PUBLIC_SUBNET_IDS
echo $PRIVATE_SUBNET_IDS
echo $KONG_REPOSITORY_URL
echo $APP_REPOSITORY_URL

STACK_NAME="${ENV}-ecs-ec2"

aws cloudformation deploy --template-file ecs-ec2-kong-app.yml --stack-name ${STACK_NAME} --capabilities CAPABILITY_IAM --parameter-overrides \
  "DesiredCapacity=${DESIRED_CAPACITY}" "MaxSize=${MAX_CAPACITY}" \
  "KongImage=${KONG_REPOSITORY_URL}" "AppImage=${APP_REPOSITORY_URL}" \
  "PublicSubnetId=${PUBLIC_SUBNET_IDS}" "PrivateSubnetId=${PRIVATE_SUBNET_IDS}" "VpcId=${VPC_ID}" "KeyName=abhi-ecs-ec2-access"
