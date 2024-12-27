#! /usr/bin/env bash

declare INSTALLDIR=$1

[ $(id -u) != 0 -a "x${INSTALLDIR}" == "x" ] && { echo "Be root to install, or choose user directory"; exit 1; }

[ $(id -u) == 0 -a "x${INSTALLDIR}" == "x" ] && INSTALLDIR="/usr/local/bin"

[ ! -d "${INSTALLDIR}" ] && { echo "${INSTALLDIR} doesn't exist!"; exit 2; }

cp -v -p shcatalog.sh ${INSTALLDIR}/shcatalog.sh

exit 0