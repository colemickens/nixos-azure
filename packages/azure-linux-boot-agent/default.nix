{ stdenv, rustPlatform, fetchFromGitHub }:

let
  metadata = import ./metadata.nix;
in
rustPlatform.buildRustPackage rec {
  pname = "azure-linux-boot-agent";
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = "colemickens";
    repo = "azure-linux-boot-agent";
    rev = metadata.rev;
    sha256 = metadata.sha256;
  };

  cargoSha256 = metadata.cargoSha256;

  meta = with stdenv.lib; {
    description = "";
    homepage = "https://github.com/colemickens/azure-linux-boot-agent";
    license = licenses.gpl3;
    maintainers = [ maintainers.colemickens ];
  };
}