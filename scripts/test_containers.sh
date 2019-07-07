#!/usr/bin/env bash


is_application_status_up() {
  [[ "$(curl -s  -f "127.0.0.1:${APP_PORT}/health" | jq -r ".status")" == "UP" ]]
}

is_kong_proxy_listener_configured() {
  
  [[ "$(curl -s  -f "127.0.0.1:${KONG_ADMIN_LISTEN}" | jq -r ".configuration.proxy_listen[0]")" == "0.0.0.0:${KONG_PROXY_LISTEN}" ]] 
}

is_kong_app_forward_configured() {
  
  [[ "$(curl -s  -f "127.0.0.1:${KONG_ADMIN_LISTEN}/services" | jq -r ".data[0].port")" == "${APP_PORT}" ]] 
}

if ! is_application_status_up ; then
  echo "ERROR: Failed to connect the test application"
  exit 1
fi

if ! is_kong_proxy_listener_configured ; then
  echo "ERROR: Failed to find proxy configuration in Kong app gateway"
  exit 1
fi

if ! is_kong_app_forward_configured ; then
  echo "ERROR: Failed to find services configuration in Kong app gateway"
  exit 1
fi
