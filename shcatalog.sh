#!/usr/bin/env bash

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

declare -r TRUE="/usr/bin/true"
declare -r MKDIR="/usr/bin/mkdir"
declare -r CAT="/usr/bin/cat"
declare -r CP="/usr/bin/cp"
declare -r LS="/usr/bin/ls"
declare -r SORT="/usr/bin/sort"
declare -r GREP="/usr/bin/grep"
declare -r BASENAME="/usr/bin/basename"

declare -r DIALOG="/usr/bin/dialog"

help_me()
{
  echo ""
}

die_with()
{
# Die with some explain.
# $1 = String to display why died.
# $2 = Exit rc > 0.
  echo -en "\n${RED}ERROR${NORM} : $1\n"
  exit $2  
}

writedbconf()
{
# Write db config file
# $1 = directory to scan.
# $2 = Name of the file representing scanned media.
  local -r DIR2SCAN="$1"
  local -r DBNAME="$2.db"

  local -i nb=0

  nb=$(ls -1 ${CONFDIR} | grep -E "$(basename ${CONFDBFILE})(.bak)+" | wc -l)
  ((nb=nb+1))
  cp ${CONFDBFILE} ${CONFDBFILE}.bak.${nb}

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

    [ $rc -ge 1 ] && break

    if [ -d "${dir2scan}" ]
    then
      ${DIALOG} --output-fd 1 --no-collapse --yesno "$dir2scan : êtes-vous sûr ?" 0 0
      rc=$?
      [ $rc == 0 ] && break
    else
      ${DIALOG} --output-fd 1 --no-collapse --msgbox "${dir2scan} n'existe pas !" 0 0
    fi
  done

  echo "${dir2scan}"
}

choose_media_name()
{
# Ask for a filename representing the scanned media.
  local media_name=""

  media_name=$(${DIALOG}\
    --output-fd 1\
    --no-collapse\
    --inputbox "Nom du média à scanner (sans espaces) :" 0 0)

  echo "${media_name}"
}

scan()
{
# Scan media and store in given filename.
# $1 = directory to scan.
# $2 = Name of the file representing scanned media.
  local -r DIR2SCAN="$1"
  local -r MEDIANAME="${LOCALDIR}/$2.db"

  ${UPDATEDB} -v -l 0 -U ${DIR2SCAN} -o ${MEDIANAME} | tee ${TMP} | ${DIALOG} --no-collapse --progressbox 25 80
  ${DIALOG} --no-collapse --textbox ${TMP} 0 0
  ${CP} /dev/null ${TMP}
}

list()
{
# List the whole database files.
  local -r DBDIR="${LOCALDIR}"
  local -r DBLIST=$(while IFS= read -r a b; do printf "%s %s\n" $a $b; done < ${CONFDBFILE})
  local tag=""

  ${DIALOG} --output-fd 1 --no-collapse --nook --menu "Liste des media connus :" 0 0 0 ${DBLIST}
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
    --inputbox "Nom entier ou partie du fichier à rechercher (laisser vide pour tout rechercher) :" 0 0)

  [ "x${filename}" == "x" ] && filename="."

  ${CP} /dev/null ${TMP}
  for l in $(${LS} -1 ${LOCALDIR}/*.db); do ${LOCATE} -d $l ${filename} >> ${TMP}; done
  ${DIALOG} --no-collapse --textbox ${TMP} 0 0
  ${CP} /dev/null ${TMP}
}

main_menu()
{
  local dir2scan=""
  local media_name=""
  local selected=0
  local rc=1
  
  while ${TRUE}
  do
    selected=$(${DIALOG}\
      --output-fd 1\
      --title "Media catalogue"\
      --menu "Que faire ?"\
      0 0 4\
      "1" "Scanner un nouveau media"\
      "2" "Lister les medias connus"\
      "3" "Rechercher un fichier")

    [ $? -ge 1 ] && break

    case ${selected} in
      "1")
        media_name=""
        [ "x${dir2scan}" == "x" ] && dir2scan="/media"
        dir2scan=$(ask_dir2scan "${dir2scan}")

        if [ "x${dir2scan}" != "x" ]
        then
          media_name="$(choose_media_name)"
          if [ "x${media_name}" = "x" ]
          then
            dialog --output-fd 1 --no-collapse --msgbox "Pas de nom de media : abandon !" 0 0
          else
            writedbconf "${dir2scan}" "${media_name}"
            scan "${dir2scan}" "${media_name}"
          fi
        fi
        ;;
      "2")
        list
        ;;
      "3")
        search
        ;;
      *)
      ;;
    esac
  done

  return 0
}

######### main

# Some package check
[ ! -x ${UPDATEDB} ] &&  die_with "${UPDATEDB} not found ! Maybe mlocate package is missing.\n" 1
[ ! -x ${LOCATE} ] &&  die_with "${LOCATE} not found ! Maybe mlocate package is missing.\n" 1
[ ! -x ${DIALOG} ] &&  die_with "${DIALOG} not found ! Maybe dialog package is missing.\n" 1

# Create using directories if not exist.
[ ! -d ${CONFDIR} ] && ${MKDIR} -v -p ${CONFDIR}
[ ! -d ${LOCALDIR} ] && ${MKDIR} -v -p ${LOCALDIR}

main_menu

#clear
echo "Sortie"

exit 0