{ dockerTools, writeScriptBin
, bash, azure-cli, azure-storage-azcopy, azure-linux-boot-agent
, skopeo
}:

let
  dockerImage = name: dockerTools.buildImage {
    name = "${name}";
    tag = "latest";

    contents = [
      bash
      azure-cli
      azure-storage-azcopy
      azure-linux-boot-agent
      blobxfer

      nix # let's include this so we can do full e2e examples in this container
    ];

    config = {
      Cmd = [ "/bin/bash" ];
      WorkingDir = "/";
    };
  };

  dockerPushScript = name: writeScriptBin "upload-${name}.sh" ''
    set -x
    set -euo pipefail

    ${skopeo}/bin/skopeo copy \
      --insecure-policy \
      --dest-creds "''${DOCKER_HUB_USER}:''${DOCKER_HUB_CRED}" \
      "docker-archive:${dockerImage name}" \
      "docker://colemickens/azure-aio"
  '';
in {
  image = dockerImage "azure-aio";
  uploadScript = dockerPushScript "azure-aio";
}