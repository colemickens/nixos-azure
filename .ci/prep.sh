#!/usr/bin/env bash

creds="$(mktemp)"

sops --decrypt "./azure-creds.json.sops" > "${creds}"

az login --service-principal \
  --username "$(jq '.appId' "${creds}")" \
  --password "$(jq '.password' "${creds}")" \
  --tenant "$(jq '.tenantId' "${creds}")"
