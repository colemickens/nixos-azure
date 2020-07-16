{ stdenv, fetchFromGitHub, buildGoModule }:

let metadata = import ./metadata.nix; in
buildGoModule rec {
  pname = "azure-storage-azcopy";
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "azure-storage-azcopy";
    rev = metadata.rev;
    sha256 = metadata.sha256;
  };

  subPackages = [ "." ];

  vendorSha256 = metadata.vendorSha256;

  postInstall = ''
    ln -rs "$out/bin/azure-storage-azcopy" "$out/bin/azcopy"
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ colemickens ];
    license = licenses.mit;
    description = "The new Azure Storage data transfer utility - AzCopy v10";
  };
}