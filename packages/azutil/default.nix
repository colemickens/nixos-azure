{ runCommandNoCC, blobxfer, azure-cli }:

runCommandNoCC "azutil-builder" {} ''
  mkdir -p $out/bin

  cp "${./upload-vhd}" $out/bin/upload-vhd

  sed -i 's|__BLOBXFER__|${blobxfer}/bin/blobxfer|g' $out/bin/upload-vhd
  sed -i 's|__AZ__|${azure-cli}/bin/blobxfer|g' $out/bin/upload-vhd
''
