#!/usr/bin/env bash
set -euo pipefail
set -x

toplevel="@toplevel@"
image_group="@image_group@"
image_location="@image_location@"
image_name="@image_name@"
image_vhd="@image_vhd@"

deploy_name="@deploy_name@"
deploy_group="@deploy_group@"
deploy_location="@deploy_location@"
deploy_vm_sku="@deploy_vm_sku@"
deploy_disk_size_gb=@deploy_disk_size_gb@
deploy_username="@deploy_username@"
deploy_sshkey="@deploy_sshkey@"
deploy_storage_sku="Premium_LRS"
# TODO: storage sku?

identity_name="${deploy_group}-identity"
identity_name="${identity_name//./-}"

hyper_v_generation="V2"
################################################################################

function check_login() {
  if ! @az@ account get-access-token &>/dev/null; then
    @az@ login --use-device-code
  fi
}

# function deploy_vm() {
#   # ensure group
#   @az@ group create --location "${deploy_location}" --name "${deploy_group}"
#   group_id="$(@az@ group show --name "${deploy_group}" -o tsv --query "[id]")"

#   # (optional) identity
#   if ! @az@ identity show -n "${identity_name}" -g "${deploy_group}" &>/dev/null; then
#     @az@ identity create --name "${identity_name}" --resource-group "${deploy_group}"
#   fi

#   # (optional) role assignment, to the resource group, bad but not really great alternatives
#   identity_id="$(@az@ identity show --name "${identity_name}" --resource-group "${deploy_group}" -o tsv --query "[id]")"
#   principal_id="$(@az@ identity show --name "${identity_name}" --resource-group "${deploy_group}" -o tsv --query "[principalId]")"
#   until @az@ role assignment create --assignee "${principal_id}" --role "Owner" --scope "${group_id}"; do sleep 1; done

#   # get image id using image_group/image_name
#   image_id="$(@az@ image show -g "${image_group}" -n "${image_name}" -o json | jq -r .id)"

#   args=(
#     --name "${deploy_name}"
#     --resource-group "${deploy_group}"
#     --assign-identity "${identity_id}"
#     --size "${deploy_vm_sku}"
#     --os-disk-size-gb "${deploy_disk_size_gb}"
#     --image "${image_id}"
#     --admin-username "${deploy_username}"
#     --location "${deploy_location}"
#     --storage-sku "${deploy_storage_sku}"
#     --ssh-key-values "${deploy_sshkey}"
#     --accelerated-networking true
#   )

#   if [[ "${1:-""}" != "" ]]; then
#     customdata_path="${1}"; shift
#     args+=(--customdata "${customdata_path}")
#   fi

#   @az@ vm create "${args[@]}"
# }

################################################################################

function upload_image() {
  if ! @az@ group show -n "${image_group}" &>/dev/null; then
    @az@ group create --name "${image_group}" --location "${image_location}"
  fi

  # note: the disk access token song/dance is tedious
  # but allows us to upload direct to a disk image
  # thereby avoid storage accounts (and naming them) entirely!
  if ! @az@ disk show -g "${image_group}" -n "${image_name}" &>/dev/null; then
    bytes="$(stat -c %s ${image_vhd})"
    size="30"
    @az@ disk create \
      --resource-group "${image_group}" \
      --name "${image_name}" \
      --hyper-v-generation "${hyper_v_generation}" \
      --for-upload true --upload-size-bytes "${bytes}"

    timeout=$(( 60 * 60 )) # disk access token timeout
    sasurl="$(\
      @az@ disk grant-access \
        --access-level Write \
        --resource-group "${image_group}" \
        --name "${image_name}" \
        --duration-in-seconds ${timeout} \
          | jq -r '.accessSas'
    )"

    @azcopy@ copy "${image_vhd}" "${sasurl}" \
      --blob-type PageBlob 
      
    @az@ disk revoke-access \
      --resource-group "${image_group}" \
      --name "${image_name}"
  fi

  if ! @az@ image show -g "${image_group}" -n "${image_name}" &>/dev/null; then
    diskid="$(@az@ disk show -g "${image_group}" -n "${image_name}" -o tsv --query [id])"

    @az@ image create \
      --resource-group "${image_group}" \
      --name "${image_name}" \
      --source "${diskid}" \
      --hyper-v-generation "${hyper_v_generation}" \
      --os-type "linux" >/dev/null

    # takes for fucking ever:
    # like, holy shit it takes for god damn forever:...
    #@az@ disk delete \
    #  --resource-group "${image_group}" \
    #  --name "${image_name}" >/dev/null

    # TODO: do we delete the original managed disk now? Otherwise its confusing
    # to have an instance of it laying around. (normally instances of images are VM disks...)
    az image show --resource-group "${image_group}" \
      --name "${image_name}" \
      -o tsv \
      --query "[id]"
  fi
}

function az() {
  @az@ "${@}"
}

cmd="${1}"; shift
time "${cmd}" "${@}"
