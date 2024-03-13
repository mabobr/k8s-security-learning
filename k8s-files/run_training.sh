#!/bin/bash

# WHAT_TO_RUN
#  np - network policy

function separ()
{
    TXT="$*"
    echo -n ----------------------------------------
    if [[ -n ${TXT} ]] ; then
        echo -n ${TXT}
    fi
    echo
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${SCRIPT_DIR} || exit 1
echo Running traininig in ${SCRIPT_DIR} USE_HTTP_PROXY=${USE_HTTP_PROXY}

WHAT_TO_RUN="$*"
if [[ -z ${WHAT_TO_RUN} ]] ; then
   WHAT_TO_RUN=all
fi
echo   WHAT_TO_RUN=${WHAT_TO_RUN}   

echo ${WHAT_TO_RUN} | grep -q -e "\ball\b" -e "\b\npb"
test $? = "0" && . ${SCRIPT_DIR}/network_policy.sh

exit 0