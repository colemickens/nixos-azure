#!/usr/bin/env bash
set -euo pipefail
set -x

AZURE_GROUP="${AZURE_GROUP:="defaultaz1"}"

function az() { time command az "${@}"; }

function boot() {
  workdir="$(mktemp -d)"
  image_id="${1}"

  ssh-keygen -t rsa -N "" -f "${workdir}/id_rsa"
  ssh-keygen -y -f "${workdir}/id_rsa" > "${workdir}/id_rsa.pub"
  sshpubkey="$(cat "${workdir}/id_rsa.pub")"

  deploy="${AZURE_GROUP}"
  username="azureuser"
  location="westus2"
  size="Standard_D2s_v3"

  az group create -n "${deploy}" -l "${location}"

  az vm create \
    --name "${deploy}" \
    --resource-group "${deploy}" \
    --size "${size}" \
    --image "${image_id}" \
    --admin-username "${username}" \
    --location "${location}" \
    --ssh-key-values "${sshpubkey}" \
    --ephemeral-os-disk true \
    --storage-sku Premium_LRS
}

function upload() {
  builddir="${1}"

  image_group="${AZURE_GROUP}"
  image_location="${AZURE_LOCATION:-"westus2"}"
  image_strg_acct="${AZURE_GROUP//-}"
  #image_gallery_name="${AZURE_GROUP}"

  image_vhd="$(readlink -f ${builddir}/disk.vhd.zstd)"
  image_filename="$(basename $(readlink -f ${image_vhd}) ".zstd")"
  image_definition_name="$(cat ${builddir}/name)"
  image_definition_publisher="$(cat ${builddir}/publisher)"
  image_definition_offer="$(cat ${builddir}/offer)"
  image_definition_sku="$(cat ${builddir}/sku)"
  image_definition_version="$(basename ${image_filename} ".vhd")"
  image_target_regions=("westus2=2")
  hyper_v_generation="V2"
  
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
    | time blobxfer upload \
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

cmd="${1}"; shift
time "${cmd}" "${@}"
