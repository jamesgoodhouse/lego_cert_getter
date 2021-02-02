#!/bin/bash

set -euf -o pipefail

lego_path=${LEGO_PATH-/etc/lego}
creds_file="$lego_path/creds"
domains_file="$lego_path/domains"
key_type=${LEGO_KEY_TYPE-rsa4096}
server="${LEGO_SERVER-https://acme-v02.api.letsencrypt.org/directory}"

_lego () {
  lego --accept-tos \
       --dns="$DNS_PROVIDER" \
       --dns.resolvers="$DNS_RESOLVER" \
       --domains="$1" \
       --email="$EMAIL" \
       --key-type="$key_type" \
       --path="$lego_path" \
       --server="$server" \
       "$2"
}

load_creds () {
  while IFS= read -r line; do
    export "${line?}"
  done < "$creds_file"
}

renew () {
  echo renewing certificate for "$1"
  _lego "$1" renew
}

create () {
  echo creating certificate for "$1"
  _lego "$1" run
}

load_creds

while read -r domain; do
  list_names=$(lego --path="$lego_path" list -n | grep -c "$domain")

  if [ "$list_names" -eq 1 ]; then
    renew "$domain"
  elif [ "$list_names" -gt 1 ]; then
    echo "too many domains found"
    exit 1
  else
    create "$domain"
  fi
done < "$domains_file"
