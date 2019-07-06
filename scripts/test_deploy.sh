#!/bin/sh -eu

MAX_RETRIES=${MAX_RETRIES:-80}

is_health_status_up() {
  local dns="$1"
  
  [[ "$(curl -s  -f "${dns}" | jq -r ".status")" == "UP" ]]
}

try_remote_status() {
  local dns="$1"  
  local max_retries="$2"

  retries=0
  until is_health_status_up "$dns" ; do
      retries=$(expr ${retries} + 1)
      if [[ ${retries} -eq ${max_retries} ]]; then
        echo "\nERROR: test failed after ${max_retries} attempts!"
        exit 1
      fi
      printf '.'
      sleep 5
  done
  echo "Found status message in ${retries} attempts"
}

ALB_DNS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[0].OutputValue')
if [[ ${ALB_DNS} == "null" ]] || [[ -z "${ALB_DNS}" ]]; then
  aws cloudformation describe-stacks --stack-name ${STACK_NAME}
  echo "\nERROR: Could not get ALB DNS from Cloudformation stack"
  exit 1
fi
echo "ALD DNS: ${ALB_DNS}"
try_remote_status "${ALB_DNS}" "${MAX_RETRIES}"

