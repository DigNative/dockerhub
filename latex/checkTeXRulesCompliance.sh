#!/bin/bash
set -e
shopt -s lastpipe

CLR_DARK_GRAY='\033[1;30m'
CLR_YELLOW='\033[1;33m'
CLR_RED='\033[0;31m'
CLR_GREEN='\033[0;32m'
CLR_NC='\033[0m' # No Color

function msgNormal {
    echo -e "[checkTeXRulesCompliance] $1"
}

function msgFailure {
    echo -e "${CLR_RED}[checkTeXRulesCompliance] Compliance violation: $1${CLR_NC}"
}


msgNormal "Running compliance checks for all TeX files..."
exitCode=0

# collect all TeX files
find . -type f -name '*.tex' -print0 | while IFS= read -r -d '' texFile; do
   
    # check line ending style
    if ! dos2unix < "${texFile}" | cmp -s - "${texFile}"; then
        exitCode=1
        msgFailure "No Unix line endings in file '${texFile}'."
    fi
    
    # file encoding
    if [[ $(file -bi "${texFile}") =~ charset=(.*) ]]; then
        exitCode=1
        if [[ "${BASH_REMATCH[1]}" != "utf-8" && "${BASH_REMATCH[1]}" != "us-ascii" ]]; then
            msgFailure "Wrong file encoding '${BASH_REMATCH[1]}' (not UTF-8 or ASCII) in file '${texFile}'."
        fi
    fi
    
    # tabs instead of spaces
    if grep -q $'\t' "${texFile}"; then
        exitCode=1
        msgFailure "Detected tabs instead of spaces in file '${texFile}'."
    fi
done

exit $exitCode