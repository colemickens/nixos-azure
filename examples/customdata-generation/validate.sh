# TODO:

# generation mode should take extra binary caches that it will pull from

# update with metadata image

image_id="/subscriptions/aff271ee-e9be-4441-b9bb-42f5af4cbaeb/resourceGroups/29381-20.09.20200729.d3ff247/providers/Microsoft.Compute/images/nixos"

# update from some build command
generation="/nix/store/..."

# create customdata.txt with our generation
customdata="$(mktemp)"
echo "#generation" >> $customdata
echo "${generation}" >> $customdata

sshpubkey="$(ssh-add -L)"
name="nixos-$RANDOM"

az group create -n "${name}" -l "westus2"
az vm create \
  --name "${name}" \
  --resource-group "${name}" \
  --size "Standard_D2s_v3" \
  --image "${image_id}" \
  --customdata "@${customdata}" \
  --os-disk-size 1024 \
  --admin-username "azureuser" \
  --location "westus2" \
  --ssh-key-values "${sshpubkey}"
```