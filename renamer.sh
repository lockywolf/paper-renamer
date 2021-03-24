#!/usr/bin/env bash

set -e
set -u

declare MY_MAX_FILENAME_LEN
MY_MAX_FILENAME_LEN=120

normalize_string() {
    # v="hell#, world!(12)@"; v=${v// /_}; printf '%s\n' "${v//[^a-zA-Z0-9_-]}"
    local v="$1"
    v=${v// /_};
    printf '%s' "${v//[^a-zA-Z0-9_-]}"
}

die() { echo "$@" 1>&2 ; exit 1; }

usage() {
    echo "usage:"
    echo -e "\t./renamer.sh <filename>"
}

# TODO instead of dying, we should intelligently find the title
die_if_empty() {
    local str=$1
    local type=$2
    if [[ -z "${str// }" ]]; then
        die "Couldn't find $type"
    fi
}

if [ "$#" -ne 1 ]; then
    usage
    die "Incorrect number of arguments"
fi

pdf="$1"

if [ ! -f "$pdf" ]
then
    usage
    die "File $pdf does not exists"
fi

# get title, note that xargs is used to trim
title=$(pdfinfo "$pdf" | egrep '^Title' | sed 's/^Title:[[:space:]]*//g' |  head -c "$MY_MAX_FILENAME_LEN" | xargs | sed 's/[[:space:]]/-/g')
die_if_empty "$title" "title"

# get authors
IFS=',' read -ra names <<< "$(pdfinfo "$pdf" | egrep '^Author:[[:space:]]*' | sed 's/^Author:[[:space:]]*//g')"
#author=$(echo "${names[0]}" | awk '{print $NF}')
author=$(normalize_string "${names[0]}")
die_if_empty "$author" "author"

# get year
#  | awk '{print $NF}')
year=$(pdfinfo "$pdf" | egrep '^CreationDate' | cut -c 15- )
year=$(normalize_string "$year")
die_if_empty "$year" "year"

filename="$(dirname "$pdf")/${author}_${year}_${title}.pdf"
printf "Renaming $pdf into $filename\n" "$pdf" "$filename"
mv "$pdf" "$filename"

