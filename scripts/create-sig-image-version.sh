#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -euo pipefail
set -x

url="${1}"

AZURE_GROUP="${AZURE_GROUP:-"test${RANDOM}${RANDOM}"}"

image_definition_name="$(cat ${out}/name)"
image_definition_publisher="$(cat ${out}/publisher)"
image_definition_offer="$(cat ${out}/offer)"
image_definition_sku="$(cat ${out}/sku)"
image_definition_version="$(cat ${out}/version)"

  if ! az sig show --gallery-name "${image_gallery_name}" --resource-group "${image_group}"; then
    az sig create \
      --resource-group "${image_group}" \
      --gallery-name "${image_gallery_name}"
  fi

  if ! az sig image-definition show ... ; then
    az sig image-definition create \
      --resource-group "${image_group}" \
      --gallery-name "${image_gallery_name}" \
      --gallery-image-definition "${image_definition_name}" \
      --publisher "${image_definition_publisher}" \
      --offer "${image_definition_offer}" \
      --sku "${image_definition_sku}" \
      --os-type Linux \
      --os-state generalized
  fi

  # check if the SIG version already exists, error if it does
  # check if blob exists, error if it does
  if az sig image-version show "" ; then
    echo "the image-version already exists" > /dev/stderr
    exit 1
  fi
  az sig image-version create \
    --resource-group "${image_acct_group}" \
    --gallery-name "${image_gallery_name}" \
    --gallery-image-definition "${image_definition_name}" \
    --gallery-image-version "${image_definition_version}" \
    --target-regions "${image_target_regions[@]}" \
    --managed-image "${image_id}"