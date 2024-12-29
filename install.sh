#! /usr/bin/env bash

declare -r TMPSCHCAT="shcatalog.sh-TMP"

declare INSTALLDIR=$1
declare LANGDIR="${INSTALLDIR}/LANG"

[ $(id -u) != 0 -a "x${INSTALLDIR}" == "x" ] && { echo "Be root to install, or choose an user directory"; exit 1; }

[ $(id -u) == 0 -a "x${INSTALLDIR}" == "x" ] && { INSTALLDIR="/usr/local/bin"; LANGDIR="/usr/local/etc/shcatalog_LANG"; mkdir ${LANGDIR}; }

[ ! -d "${INSTALLDIR}" ] && { echo "${INSTALLDIR} doesn't exist!"; exit 2; }
[ ! -d "${LANGDIR}" ] && { echo "${LANGDIR} doesn't exist!"; exit 2; }

sed "s|declare -r DIRFILECLANG=\"./LANG\"|declare -r DIRFILECLANG=\"${LANGDIR}\"|" shcatalog.sh > ${TMPSCHCAT}
chmod -v 755 ${TMPSCHCAT}

mv -v ${TMPSCHCAT} ${INSTALLDIR}/shcatalog.sh
cp -a -v ./LANG/* ${LANGDIR}

exit 0