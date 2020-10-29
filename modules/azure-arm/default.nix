{ pkgs }:

{
  exp = {
    mkGroupTemplate = { resources }: {

    };
    mkComputeVirtualMachine = {}: {

    };
    mkStorageAccount = { name, location, containerName?name }: {
      type = "Microsoft.Storage/storageAccounts";
      apiVersion = "2019-06-01";
      name = name;
      location = location;
      sku = {
        name = "Standard_LRS";
        tier = "Standard";
      };
      kind = "StorageV2";
      properties = {
        accessTier = "Hot";
      };
      resources = [
        {
          type = "blobServices/containers";
          apiVersion = "2019-06-01";
          name = containerName;
          dependsOn = [
            "Microsoft.Storage/storageAccounts/${name}"
          ];
        }
      ];
    };
  };
}