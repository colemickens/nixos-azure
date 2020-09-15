{ runCommandNoCC }:

runCommandNoCC "azutil-builder" {} ''
  mkdir -p $out/bin
  cp "${./azutil.sh}" $out/bin/azutil
''