#!/bin/bash
set -eu
export WINEDEBUG=-all

TEMP=$(mktemp -d)
echo "Usando '$TEMP'."
cp unittest.zr16 zr16.asm "$TEMP"
cd $TEMP
fasmg unittest.zr16 output.fasmg -i 'include "zr16.asm"'
cp unittest.zr16{,.tmp}
head -n-1 unittest.zr16.tmp | perl -pe 's/\[(.+?)\]/($1)/g' | perl -pe 's/dw/dc/g' > unittest.zr16
ZR16_Compiler.exe unittest.zr16
diff --color -s output.fasmg unittest.zr16.bin
rm -r "$TEMP"
