#! /bin/sh

#
# Headers and Logging
#

red=$(tput setaf 1)
bold=$(tput bold)
reset=$(tput sgr0)
green=$(tput setaf 76)
purple=$(tput setaf 171)

e_header() { printf "\n${bold}${purple}==========  %s  ==========${reset}\n" "$@" 
}
e_success() { printf "${green}✔ %s${reset}\n" "$@"
}
e_error() { printf "${red}✖ %s${reset}\n" "$@"
}
e_bold() { printf "${bold}%s${reset}\n" "$@"
}
e_arrow() { printf "➜ $@\n"
}

#
# Processing arguments
#

show_help() {
  printf "Usage: $(basename "$0") [-d DESTINATION] [-s SIZE] [-h]\n"
  printf "    -d DESTINATION destination folder (default is ~/Pictures/Wallpapers)\n"
  printf "    -s SIZE        image size (default is 2560x1600)\n"
  printf "    -h             show this help\n"
}

validate_size() {
  if [[ ! $SIZE =~ ^[0-9]+x[0-9]+$ ]]; then
    e_error "Invalid size parameter: $SIZE (e.g. 1900x1600)"
    show_help
    exit 0
  fi
}

START=`date +%s`

DESTINATION="$HOME/Pictures/Wallpapers"
SIZE="2560x1600"

OPTIND=1
while getopts ":d:s:h" opt; do
  case "$opt" in
    d) DESTINATION=$OPTARG
      ;;
    s) SIZE=$OPTARG
      validate_size
      ;;
    h) show_help
      exit 1
      ;;
    \?) e_error "Invalid option: -$OPTARG" >&2
      show_help
      exit 1
      ;;
    :) e_error "Option -$OPTARG requires an argument" >&2
      show_help
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))"

# Checking that WGET is installed
if ! [ -x "$(command -v wget)" ]; then
  e_error "Please install wget or set it in your path"
  exit 0
fi

#
# Main
#
e_header LiftDownloader
echo
e_bold "Downloading $SIZE wallpapers to $DESTINATION"

HOSTURL="http://interfacelift.com"
HTML_SOURCE_FILE="html_source.temp"
URL_LIST_FILE="extracted_url_list.temp"
MAX_PAGE=18

rm -Rf $DESTINATION
mkdir -p $DESTINATION

for CURRENT_PAGE in `seq 1 $MAX_PAGE`
do
    wget -q --user-agent="Opera" --output-document=$HTML_SOURCE_FILE $HOSTURL"/wallpaper_beta/downloads/date/widscreen/"$SIZE"/index"$CURRENT_PAGE".html"

    cat $HTML_SOURCE_FILE | grep -o -E /wallpaper/[a-z0-9]+/[0-9]+_.*_.*\.jpg | grep $SIZE > $URL_LIST_FILE

    for FILENAME in `cat $URL_LIST_FILE`
    do
        e_arrow $(basename $FILENAME)
        wget -q --user-agent="Opera" -P $DESTINATION $HOSTURL$FILENAME
    done

    rm $HTML_SOURCE_FILE
    rm $URL_LIST_FILE
done

END=`date +%s`
RUNTIME=$((END-START))
FILENUMBER=$(find $DESTINATION | wc -l)
TOTALSIZE=$(du -h $DESTINATION | cut -f1)

echo
e_success "Downloaded $FILENUMBER files ($TOTALSIZE) in $RUNTIME seconds"

