#!/usr/bin/env bash
set -euo pipefail
set -x

name="job${JOBID:-"${RANDOM}"}"
workdir="$(mktemp -d)"

function az() { time command az "${@}"; }
function cleanup() {
  az group delete --yes --no-wait --name "${name}"
  rm -rf "${workdir}"
}

trap cleanup ERR

ssh-keygen -t rsa -N "" -f "${workdir}/id_rsa"
ssh-keygen -y -f "${workdir}/id_rsa" > "${workdir}/id_rsa.pub"
sshpubkey="$(cat "${workdir}/id_rsa.pub")"

# build and upload the image
image_id="$(AZURE_GROUP=${name} ../../scripts/upload-image.sh '.#examples.basic.azureImage')"

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

ip="$(az vm show -n "${name}" -l "${location}" -o tsv \
  --query '[0].virtualMachine.network.publicIpAddresses[0].ipAddress')"

# test dynamic user
ssh "${username}@${ip}" who

# test hard-coded user (specific to "basic" example)
ssh "azurenixosuser@${ip}" who

echo "success"
