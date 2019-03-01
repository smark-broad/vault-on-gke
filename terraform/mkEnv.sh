#!/bin/bash

PROG=$( basename $0 )
env_arg=""
proj_arg=""
env_env="${ENVIRONMENT}"
proj_env="${PROJECT_NAME}"

SCRIPT_DIR="$( cd -P "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
if [ -f "${SCRIPT_DIR}/config.sh" ]
then
   source "${SCRIPT_DIR}/config.sh"
fi

usage() {
  echo
  echo "Usage: ${PROG} [-e ENVIRONMENT] [-p PROJECT]"
  echo
}

# process getopts
while getopts :e:p:h FLAG; do
   case $FLAG in
    h) usage
       exit 0
      ;;
    e) env_arg="${OPTARG}"
      ;;
    p) proj_arg="${OPTARG}"
      ;;
   esac
done

shift $((OPTIND-1))

# ENVIRONMENT and PROJECT_NAME are determined using the following precedence
#  (lowest) source it from config.sh
#  if ENVIRONMENT environment var exists set it to that
#  (highest) if passed in set it to that value

if [ -z "${env_env}" -o "x${env_env}" == "x" ]; then
    if [ ! -z "${env_arg}" ]; then
         ENVIRONMENT="${env_arg}"
    fi
else
    if [ ! -z "${env_arg}" ]; then
         ENVIRONMENT="${env_arg}"
    else
         ENVIRONMENT="${env_env}"
    fi
fi

if [ -z "${proj_env}" -o "x${proj_env}" == "x" ]; then
    if [ ! -z "${proj_arg}" ]; then
         PROJECT_NAME="${proj_arg}"
    fi
else
    if [ ! -z "${proj_arg}" ]; then
         PROJECT_NAME="${proj_arg}"
    else
         PROJECT_NAME="${proj_env}"
    fi
fi

if [ -z "${VAULT_TOKEN}" -o "x${VAULT_TOKEN}" == "x" ]; then
    export VAULT_TOKEN=${2-`cat /root/.vault-token`}
fi

if [ -z "${ENVIRONMENT}" ]; then
    echo "FATAL ERROR: Environment not defined!"
    exit 1
fi

if [ -z "${VAULT_TOKEN}" ]; then
    echo "FATAL ERROR: Vault token not provided!"
    exit 1
fi

if [ -z "${PROJECT_NAME}" -o "x${PROJECT_NAME}" == "x" ]; then
    echo "FATAL ERROR: Project not set"
    exit 1
fi

export PROJECT_NAME ENVIRONMENT
#CONFIG_TEMPLATE='config.sh.ctmpl'
#OVERRIDE_TEMPLATE='env_override.tf.ctmpl'
#CONFIG='config.sh'

#OVERRIDE="${ENVIRONMENT}_override.tf"
#SVCFILE="${ENVIRONMENT}_svc.json"
#CREDENTIAL_PATH="secret/devops/terraform/${ENVIRONMENT}/${PROJECT_NAME}/credentials"

echo "Rendering environment ctmpls"
# process all env_ ctmpls
ls env_*.ctmpl | while read file
do
    rootname="${file%.ctmpl}"
    newname=`echo $rootname | sed -e "s;^env_;${ENVIRONMENT}_;"`
    echo "$rootname -> $newname"
    /usr/local/bin/consul-template \
        -once \
        -config=/etc/consul-template/config/config.json \
        -log-level=err \
        -template=${file}:${newname}
done

echo "Rendering other ctmpls"
# process all other ctmpls that do not start with env_
find . -name "*.ctmpl" -print | grep -Ev "^./env" | while read file
do
    rootname="${file%.ctmpl}"
    echo "$file -> $rootname"
    /usr/local/bin/consul-template \
        -once \
        -config=/etc/consul-template/config/config.json \
        -log-level=err \
        -template=${file}:${rootname}
done

# doing metadata dir as well in case
#cd metadata
#ls *.ctmpl | while read file
#do
#    rootname="${file%.ctmpl}"
#    echo "$file -> $rootname"
#    /usr/local/bin/consul-template \
#        -once \
#        -config=/etc/consul-template/config/config.json \
#        -log-level=err \
#        -template=${file}:${rootname}
#done
