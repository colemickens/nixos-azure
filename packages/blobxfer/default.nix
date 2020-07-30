{ lib, pythonPackages, buildPythonApplication, fetchFromGitHub, bitstring_, ... }:

buildPythonApplication rec {    
  pname = "blobxfer";    
  version = "1.9.4";
    
  src = fetchFromGitHub {    
    owner = "Azure";
    repo = "blobxfer";    
    rev = version;
    sha256 = "1s25hba73h82a2bk29bxa1nabd7zw25hm8m38ziqxlbv1x6i8gkf";
  };

  propagatedBuildInputs = with pythonPackages; [
    azure-storage-blob
    azure-storage-file
    bitstring_
    click
    cryptography
    future
    python-dateutil
    requests
    ruamel_yaml
    scandir
  ];

  checkInputs = with pythonPackages; [ pytest ];

  postPatch = ''
    sed -i 's/requests~=2.22.0/requests~=2.23.0/g' setup.py
  '';

  meta = {
    description = " Azure Storage transfer tool and data movement library ";
    homepage = "https://github.com/Azure/blobxfer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colemickens ];
  };
}
