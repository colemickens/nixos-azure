{ stdenv, buildPythonPackage, fetchFromGitHub }:

buildPythonPackage rec {
  pname = "bitstring";
  version = "3.1.7";

  src = fetchFromGitHub {
    owner = "scott-griffiths";
    repo = "bitstring";
    rev = "bitstring-${version}";
    sha256 = "17x7mkg0zbby4ivizbmrjf1z4p2g1dkq2hvx9wr6akk2mnby361n";
  };

  meta = with stdenv.lib; {
    description = "Module for binary data manipulation";
    homepage = "https://github.com/scott-griffiths/bitstring";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ bjornfor ];
  };
}
