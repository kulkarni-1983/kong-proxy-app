#!/usr/bin/env bash

set -eu

VAR=$(env|grep ^$1\\b|cut -d '=' -f2)

if [ -z "$VAR" ]; then
  VAR=$(grep ^$1\\b .env|cut -d '=' -f2)
fi

echo "$VAR"