#!/usr/bin/env bash
set -euo pipefail
set -x

image_id="${1}"
name="job${JOBID:-"$(date '+%s')"}"
workdir="$(mktemp -d)"

function az() { time command az "${@}"; }

function runtest() {
  ssh-keygen -t rsa -N "" -f "${workdir}/id_rsa"
  ssh-keygen -y -f "${workdir}/id_rsa" > "${workdir}/id_rsa.pub"
  sshpubkey="$(cat "${workdir}/id_rsa.pub")"

  username="azure${name}"
  location="westus2"
  size="Standard_D2s_v3"

  az group create -n "${name}" -l "${location}"

  az vm create \
    --name "${name}" \
    --resource-group "${name}" \
    --size "${size}" \
    --image "${image_id}" \
    --admin-username "${username}" \
    --location "${location}" \
    --ssh-key-values "${sshpubkey}" \
    --ephemeral-os-disk true
}

runtest

