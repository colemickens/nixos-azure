#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -euo pipefail
set -x

drv="${1}"
out="$(mktemp -u)"
nix --experimental-features 'nix-command flakes' build "${DIR}/../${drv}" --out-link "${out}"
function cleanup () { rm -rf "${out}"; }
trap cleanup EXIT

AZURE_GROUP="${AZURE_GROUP:-"test${RANDOM}${RANDOM}"}"

image_group="${AZURE_GROUP}"
image_location="${AZURE_LOCATION:-"westus2"}"
image_strg_acct="${AZURE_GROUP//-}"
image_gallery_name="${AZURE_GROUP}"

image_vhd="$(readlink -f ${out}/disk.vhd.zstd)"
image_filename="$(basename $(readlink -f ${image_vhd}) ".zstd")"
image_definition_name="$(cat ${out}/name)"
image_definition_publisher="$(cat ${out}/publisher)"
image_definition_offer="$(cat ${out}/offer)"
image_definition_sku="$(cat ${out}/sku)"
image_definition_version="$(basename ${image_filename} ".vhd")"
image_target_regions=("westus2=2")
hyper_v_generation="V2"

function az() { time command az "${@}"; }

function check_login() {
  if ! az account get-access-token &>/dev/null; then
    az login --use-device-code
  fi
    
  az provider register --namespace Microsoft.Storage
  az provider register --namespace Microsoft.Network
  az provider register --namespace Microsoft.Compute
}

function upload_image() {
  if ! az group show -n "${image_group}" &>/dev/null; then
    az group create --name "${image_group}" --location "${image_location}"  &>/dev/stderr
  fi

  if ! az storage account show --name "${image_strg_acct}" &>/dev/null; then
    az storage account create -n "${image_strg_acct}" -g "${image_group}" -l "westus2" --sku "Standard_LRS"  &>/dev/stderr
  fi

  if ! az storage container show --account-name "${image_strg_acct}" --name "vhd" &>/dev/null; then
    #az storage container create --verbose --auth-mode login --account-name "${image_strg_acct}" --name "vhd" &>/dev/stderr
    az storage container create --verbose --account-name "${image_strg_acct}" --name "vhd" &>/dev/stderr
  fi

  sasurl="$(az storage blob generate-sas \
    --permissions acdrw \
    --expiry "$(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')" \
    --account-name "${image_strg_acct}" \
    --container-name "vhd" \
    --name "${image_filename}"\
    --full-uri -o tsv)"

  zstdcat "${image_vhd}" \
    | blobxfer upload \
      --storage-url "${sasurl}" \
      --local-path -

  bloburl="$(az storage blob url \
    --account-name "${image_strg_acct}" \
    --container-name "vhd" \
    --name "${image_filename}" \
    -o tsv)"

  if ! az image show -g "${image_group}" -n "${image_filename}" &>/dev/null; then
    az image create \
      --resource-group "${image_group}" \
      --name "${image_filename}" \
      --source "${bloburl}" \
      --hyper-v-generation "${hyper_v_generation}" \
      --os-type "linux" >/dev/null

    az image show --resource-group "${image_group}" \
      --name "${image_filename}" \
      -o tsv \
      --query "[id]"
  fi
}

check_login
time upload_image "${@}"
