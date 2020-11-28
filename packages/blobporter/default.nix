{ stdenv, fetchFromGitHub, buildGoModule }:

let metadata = import ./metadata.nix; in
buildGoModule rec {
  pname = "blobporter";
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "blobporter";
    rev = metadata.rev;
    sha256 = metadata.sha256;
  };

  subPackages = [ "." ];

  vendorSha256 = null;

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ colemickens ];
    license = licenses.mit;
    description = "Highly concurrent data transfer tool for Azure Blob Storage.";
  };
}