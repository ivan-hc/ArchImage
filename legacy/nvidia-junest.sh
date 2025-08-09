#!/bin/sh

conty_minimal="https://github.com/ivan-hc/Conty/releases/download/continuous-SAMPLE/conty.sh"

if command -v curl >/dev/null 2>&1; then
	echo "Downloading Conty"
	curl -#Lo conty.sh "${conty_minimal}"
else
	echo "You need \"curl\" to download this script"; exit 1
fi
[ -f ./conty.sh ] && chmod a+x ./conty.sh && ./conty.sh bwrap --version | grep -v bubblewrap
rm -f ./conty.sh
