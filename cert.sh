#!/bin/bash

set -euf -o pipefail

creds_file="$lego_path/creds"
dns_provider=namecheap
dns_resolver=dns1.registrar-servers.com
domains_file="$lego_path/domains"
email=admin@goodhouse.io
key_type=rsa4096
lego_path=/etc/lego
server="${LEGO_SERVER-https://acme-v02.api.letsencrypt.org/directory}"

_lego () {
  lego --accept-tos \
       --dns="$dns_provider" \
       --dns.resolvers="$dns_resolver" \
       --domains="$1" \
       --email="$email" \
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
  if [ "$(lego --path="$lego_path" list -n | grep -c "$domain")" -eq 1 ]; then
    renew "$domain"
  else
    create "$domain"
  fi
done < "$domains_file"
