#!/bin/bash

# This scripr will run it all
# Requirements:
# - vagrant at machine allowing 4 VMs - adjust Vagnarfile to match your HW capabilities
# - the repo is configuret for kvl/libvirt, adjust Vagrantfiel to your platform

# How to use after git clone, at host machive:
#: $ VERBOSE=1 bash ./run-all.sh

VERBOSE=${VERBOSE:-0}
# disable/enable vagrant verbose
VAGRANT_VERBOSE=${VAGRANT_VERBOSE:-0}
# PROXY may be implemented later - when network is up
export USE_HTTP_PROXY=${USE_HTTP_PROXY:-0}

PRIVATE_KEYFILE=k8s.key

export POD_NETWORK_CIDR=${POD_NETWORK_CIDR:-10.10.0.0/16}

#####################################################
function debug()
{
    if [[ ${VERBOSE} != "0" ]] ; then
        local TXT="$*"
        echo $(date "+%Y-%m-%d %T ")${TXT}
    fi
}

#####################################################
#  MAIN
#####################################################
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ ${EUID} == "0" ]] ; then
    echo $0 error: must not be root
    exit 1
fi

if [[ ${VAGRANT_VERBOSE} != "0" ]] ; then
    VAGRANT_OPTIONS=""
else
    VAGRANT_OPTIONS="--no-tty"
fi

# all machines should be in the same state - not checking
vagrant status | grep -Fq "not created"
if [[ $? == "0" ]] ; then
    PRIVATE_KEYFILE=${SCRIPT_DIR}/${PRIVATE_KEYFILE}
    if [[ ! -f ${PRIVATE_KEYFILE} ]] ; then
        debug Private key file not found, generating ssh keypait
        ssh-keygen -t ecdsa -f ${PRIVATE_KEYFILE} || exit 1
    fi

    debug Machine not created, spinning up VMs w/ provisioning    
    vagrant ${VAGRANT_OPTIONS} up --provision-with system-init,reload-after-update,copy-k8s-priv-key,copy-k8s-pub-key || exit 1

    debug k8s, proxy initialization at VMs
    echo Using POD_NETWORK_CIDR=${POD_NETWORK_CIDR}
    POD_NETWORK_CIDR=${POD_NETWORK_CIDR} \
    USE_HTTP_PROXY=${USE_HTTP_PROXY} \
    vagrant ${VAGRANT_OPTIONS} up --provision-with app-init || exit 1
    vagrant ${VAGRANT_OPTIONS} up --provision-with copy_join_command || exit 1
    vagrant ${VAGRANT_OPTIONS} up --provision-with join-cluster || exit 1
    vagrant ${VAGRANT_OPTIONS} up --provision-with install_cni || exit 1
fi

vagrant status | grep -Fq "shutoff"
if [[ $? = "0" ]] ; then
    debug Machine not running, spinning up VMs wo/ provisioning    
    vagrant ${VAGRANT_OPTIONS} up --no-provision || exit 1
fi

echo "Cluster status check ..."
vagrant ${VAGRANT_OPTIONS} provision --provision-with running_check || exit 1
echo "Cluster ready"


