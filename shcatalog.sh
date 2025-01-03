#!/usr/bin/env bash

declare -r DIRFILECLANG="./LANG"

declare -r RED="\033[0;31m"
declare -r GREEN="\033[0;32m"
declare -r YELLOW="\033[1;33m"
declare -r NORM="\033[0m"

declare -r LOCALDIR="${HOME}/.local/share/shcatalog"
declare -r CONFDIR="${HOME}/.config/shcatalog"
declare -r CONFDBFILE="${CONFDIR}/dbconf"

declare -r TMP="/tmp/shcatalog.log"

declare -r UPDATEDB="/usr/bin/updatedb"
declare -r LOCATE="/usr/bin/locate"
declare -r DIALOG="/usr/bin/dialog"

declare -r TRUE="/usr/bin/true"
declare -r MKDIR="/usr/bin/mkdir"
declare -r CAT="/usr/bin/cat"
declare -r CP="/usr/bin/cp"
declare -r LS="/usr/bin/ls"
declare -r SORT="/usr/bin/sort"
declare -r GREP="/usr/bin/grep"
declare -r WC="/usr/bin/wc"
declare -r CUT="/usr/bin/cut"
declare -r SED="/usr/bin/sed"
declare -r RM="/usr/bin/rm"
declare -r BASENAME="/usr/bin/basename"


help_me()
{
  echo -e "${HELPME1}"
  echo -e "${HELPME2}"
  echo -e "${HELPME3}"
  exit 1
}

die_with()
{
# Die with some explain.
# $1 = String to display why died.
# $2 = Exit rc > 0.
  echo -en "\n${RED}ERROR${NORM} : $1\n"
  exit $2
}

backup_dbconf()
{
# Write a dbconf backup.
  local -i nb=0

  nb=$(${LS} -1 ${CONFDIR} | ${GREP} -E "$(${BASENAME} ${CONFDBFILE})(.bak)+" | ${WC} -l)
  ((nb=nb+1))
  ${CP} ${CONFDBFILE} ${CONFDBFILE}.bak.${nb}
}

writedbconf()
{
# Write db config file
# $1 = directory to scan.
# $2 = Name of the file representing scanned media.
  local -r DIR2SCAN="$1"
  local -r DBNAME="$2.db"

  backup_dbconf

  echo "${DBNAME} ${DIR2SCAN}" >> ${CONFDBFILE}
}

ask_dir2scan()
{
# Ask for the directory name to scan.
# $1 = first directory root.
  local dir2scan="$1"
  local rc=0

  while ${TRUE}
  do
    dir2scan=$(${DIALOG}\
      --output-fd 1\
      --dselect "${dir2scan}" 25 40)
    rc=$?

    [ ${rc} -ge 1 ] && break

    if [ -d "${dir2scan}" ]
    then
      ${DIALOG} --output-fd 1 --no-collapse --yesno "$dir2scan : ${ASKDIR2SCAN1}" 0 0
      rc=$?
      [ ${rc} == 0 ] && break
    else
      ${DIALOG} --output-fd 1 --no-collapse --msgbox "${dir2scan} : ${ASKDIR2SCAN2}" 0 0
    fi
  done

  echo "${dir2scan}"
}

prepare_2_overwrite()
{
# Prepare to overwrite if ok for user.
# $1 = media to overwrite
  local -r media_name="$1"
  local -r dbfilename="${LOCALDIR}/${media_name}.db"
  local media_name_final=""
  local rc=0

  ${DIALOG} --output-fd 1 --no-collapse --yesno "${dbfilename} ${P2O}" 0 0
  rc=$?
  if [ ${rc} == 0 ]
  then
    [ -e "${dbfilename}" ] && ${RM} "${dbfilename}"
    backup_dbconf
    ${SED} -i "/${media_name}/d" "${CONFDBFILE}"
    media_name_final=${media_name}
  else
    media_name_final=""
  fi

  echo "${media_name_final}"
}

choose_media_filename()
{
# Ask for a filename representing the scanned media.
# $1 = directory to will be scaned.
  local -r DIR2SCAN="$1"
  local media_name=""

  media_name=$(${DIALOG}\
    --output-fd 1\
    --no-collapse\
    --inputbox "${DIR2SCAN} : ${CHOOSEDBFILENAME}" 0 0)

  [ -e "${LOCALDIR}/${media_name}.db" ] && media_name=$(prepare_2_overwrite "${media_name}")

  echo "${media_name}"
}

scan()
{
# Scan media and store in given filename.
# $1 = directory to scan.
# $2 = Name of the file representing scanned media.
  local -r DIR2SCAN="$1"
  local -r MEDIANAME="${LOCALDIR}/$2.db"

  ${UPDATEDB} -v -l 0 -U ${DIR2SCAN} -o ${MEDIANAME} | tee ${TMP} | ${DIALOG} --output-fd 1 --no-collapse --progressbox 25 80
  ${DIALOG} --output-fd 1 --no-collapse --textbox ${TMP} 0 0
  ${CP} /dev/null ${TMP}
}

list_db()
{
# List the whole database files.
  local -r DBDIR="${LOCALDIR}"
  local -r DBLIST=$(while IFS= read -r a b; do printf "%s %s\n" $a $b; done < ${CONFDBFILE})
  local rc=0
  local tag=""

  tag=$(${DIALOG} --output-fd 1 --no-collapse --menu "${LISTKNOWNMEDIA}" 0 0 0 ${DBLIST})
  rc=$?

  if [ ${rc} == 0 ]
  then
    echo -e "${tag} :" > ${TMP};
    ${LOCATE} -d ${DBDIR}/${tag} "." | ${SED} -e "s/^/    /" >> ${TMP}
    ${DIALOG} --no-collapse --textbox ${TMP} 0 0
    echo -e "" > ${TMP}
  fi
}

search()
{
# Search a file into the database files.
  local -r DBDIR="${LOCALDIR}"
  local -r DBLIST=$(for l in $(${LS} -1 ${DBDIR} | ${SORT}); do ${BASENAME} -s .db $l; done)

  local filename=""

  filename=$(${DIALOG}\
    --output-fd 1\
    --no-collapse\
    --inputbox "${SEARCHWHAT}" 0 0)

  [ "x${filename}" == "x" ] && filename="."

  echo -e "" > ${TMP}
  for l in $(${LS} -1 ${LOCALDIR}/*.db); do echo -e "${l} :" >> ${TMP}; ${LOCATE} -d ${l} ${filename} | ${SED} -e "s/^/    /" >> ${TMP}; echo "" >> ${TMP}; done
  ${SED} -i '$d' ${TMP}
  ${DIALOG} --no-collapse --textbox ${TMP} 0 0
  echo -e "" > ${TMP}
}

remove_dbfile()
{
# Remove a choosen dbfile.
  local -r DBLIST=$(while IFS= read -r a b; do printf "%s %s\n" $a $b; done < ${CONFDBFILE})
  local rc=0
  local tag=""
  local dbfilename=""

  tag=$(${DIALOG} --output-fd 1 --no-collapse --menu "${LISTKNOWNMEDIA}" 0 0 0 ${DBLIST})
  rc=$?

  if [ ${rc} == 0 ]
  then
    dbfilename="${LOCALDIR}/${tag}"

    ${DIALOG} --output-fd 1 --no-collapse --yesno "${dbfilename}\n${REMOVEDBFILE1}" 0 0
    rc=$?
    if [ ${rc} == 0 ]
    then
      [ -e "${dbfilename}" ] && ${RM} -v "${dbfilename}"
      backup_dbconf
      ${SED} -i "/${tag}/d" "${CONFDBFILE}"
      ${DIALOG} --output-fd 1 --no-collapse --msgbox "${dbfilename}${REMOVEDBFILE2}" 0 0
    else
      ${DIALOG} --output-fd 1 --no-collapse --msgbox "${REMOVEDBFILE3}" 0 0
    fi

  fi
}

main_menu()
{
  local dir2scan=""
  local media_name=""
  local selected=0

  while ${TRUE}
  do
    selected=$(${DIALOG}\
      --output-fd 1\
      --title "${MAINMENU1}"\
      --menu "${MAINMENU2}"\
      0 0 0\
      "1" "${MAINMENU3}"\
      "2" "${MAINMENU4}"\
      "3" "${MAINMENU5}"\
      "4" "${MAINMENU6}"
      )

    [ $? -ge 1 ] && break

    case ${selected} in
      "1")
        media_name=""
        [ "x${dir2scan}" == "x" ] && dir2scan="/media"
        dir2scan=$(ask_dir2scan "${dir2scan}")
        if [ "x${dir2scan}" != "x" ]
        then
          media_name="$(choose_media_filename ${dir2scan})"
          if [ "x${media_name}" = "x" ]
          then
            ${DIALOG} --output-fd 1 --no-collapse --msgbox "${MAINMENU7}" 0 0
          else
            writedbconf "${dir2scan}" "${media_name}"
            scan "${dir2scan}" "${media_name}"
          fi
        fi
        ;;
      "2")
        list_db
        ;;
      "3")
        search
        ;;
      "4")
        remove_dbfile
        ;;
      *)
      ;;
    esac
  done

  return 0
}

######### main

# !!!! To prevent a """bug""" if 'LANG=ja_JP' instead of 'LANG=ja_JP.UTF-8'.
# Maybe some other non latin langages are also like this. !!!!
[ "${LANG}" == "ja_JP" ] && LANG="ja_JP.UTF-8"

declare MYLANG="$(echo ${LANG} | ${CUT} -d "." -f 1).UTF-8"

if [ -e ${DIRFILECLANG}/${MYLANG} ]
then
  source "${DIRFILECLANG}/${MYLANG}"
else
  echo -en "Sorry, file ${YELLOW}${DIRFILECLANG}/${MYLANG}${NORM} not found ! Try to use ${YELLOW}${DIRFILECLANG}/C.UTF-8${NORM}."
  [ ! -e ${DIRFILECLANG}/C.UTF-8 ] && die_with "LANG failure : ${DIRFILECLANG}/C.UTF-8 does not exist ! Exit with rc 3 !" 3
  source "${DIRFILECLANG}/C.UTF-8"
fi

# Some package check
[ ! -x ${UPDATEDB} ] &&  die_with "${MAINMISSUPDATE}" 3
[ ! -x ${LOCATE} ] &&  die_with "${MAINMISSLOCATE}" 3
[ ! -x ${DIALOG} ] &&  die_with "${MAINMISSDIALOG}" 3

# Create using directories if not exist.
[ ! -d ${CONFDIR} ] && ${MKDIR} -v -p ${CONFDIR}
[ ! -d ${LOCALDIR} ] && ${MKDIR} -v -p ${LOCALDIR}

[ "$1" == "-h" -o "$1" == "--help" ] && help_me

main_menu

clear
echo "${MAINEXIT}"

exit 0
