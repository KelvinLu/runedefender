#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

DOMAIN=$(cat /etc/duck-dns/domain)
DOMAIN=${DOMAIN:?'no domain specified'}

TOKEN=$(cat /etc/duck-dns/token)
TOKEN=${TOKEN:?'no token configured'}

RESPONSE=$(curl --silent -k -K - <<< 'url='"https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=")

if [ ${RESPONSE:-} == 'OK' ]; then
  exit 0
elif [ ${RESPONSE:-} == 'KO' ]; then
  echo "(KO) Error updating domains='${DOMAIN}'" >&2
  exit 1
else
  exit 2
fi
