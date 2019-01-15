#!/bin/bash

##############################################################################
# Copyright 2017-2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

LOAD_ENV_FILE=${LOAD_ENV_FILE:-true}
IBM_CLOUD_LOGIN=${IBM_CLOUD_LOGIN:-false}

if [[ "$LOAD_ENV_FILE" == "true" ]]; then
  if [ ! -f ../local.env ]; then
    _err "Before deploying, copy template.local.env into local.env and fill in environment specific values."
    exit 1
  fi

  # Load configuration variables
  source ../local.env
fi

function ibmcloud_login() {
  if [[ "$IBM_CLOUD_LOGIN" == "true" ]]; then
    # remove 'ibm:yp:' prefix from region identifier if present. 
    IBMCLOUD_REGION=$(echo $IBMCLOUD_REGION | cut -f 3 -d :)
    # Skip version check updates
    ibmcloud config --check-version=false

    # Obtain the API endpoint from IBMCLOUD_REGION and set it as default
    ibmcloud api --unset
    IBMCLOUD_API_ENDPOINT=$(ibmcloud api | awk '/'$IBMCLOUD_REGION'/{ print $2 }')

    # Login to ibmcloud, generate .wskprops
    ibmcloud login --apikey $IBMCLOUD_API_KEY -a $IBMCLOUD_API_ENDPOINT
    ibmcloud target -o "$IBMCLOUD_ORG" -s "$IBMCLOUD_SPACE"
    ibmcloud fn api list > /dev/null
  fi
}

function usage() {
    echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
    set -e
    
    echo -e "Installing actions, triggers, and rules for ibm-cloud-functions-refarch-data-processing-message-hub..."
    
    echo -e "Make IBM Message Hub connection info available to IBM Cloud Functions"
    ibmcloud fn package refresh
    
    echo "Creating the message-trigger trigger"
    ibmcloud fn trigger create message-trigger \
      --feed Bluemix_${KAFKA_INSTANCE}_${KAFKA_CREDS}/messageHubFeed \
      --param isJSONData true \
      --param topic ${SRC_TOPIC}
    
    echo "Creating the package for the actions"
    ibmcloud fn package create data-processing-message-hub
    
    echo "Creating receive-consume action as a Node.js action"
    ibmcloud fn action create data-processing-message-hub/receive-consume ../runtimes/nodejs/actions/receive-consume.js
    
    echo "Creating transform-produce action as a Node.js action"
    ibmcloud fn action create data-processing-message-hub/transform-produce ../runtimes/nodejs/actions/transform-produce.js \
      --param topic ${DEST_TOPIC} \
      --param kafka ${KAFKA_INSTANCE}
    
    echo "Creating the message-processing-sequence sequence that links the consumer and producer actions"
    ibmcloud fn action create data-processing-message-hub/message-processing-sequence --sequence data-processing-message-hub/receive-consume,data-processing-message-hub/transform-produce
    
    echo "Creating the  message-rule rule that links the trigger to the sequence"
    ibmcloud fn rule create message-rule message-trigger data-processing-message-hub/message-processing-sequence
    
    echo -e "Install Complete"
}

function uninstall() {
    echo -e "Uninstalling..."
    
    ibmcloud fn rule delete --disable message-rule
    ibmcloud fn trigger delete message-trigger
    ibmcloud fn action delete data-processing-message-hub/message-processing-sequence
    ibmcloud fn action delete data-processing-message-hub/receive-consume
    ibmcloud fn action delete data-processing-message-hub/transform-produce
    ibmcloud fn package delete Bluemix_${KAFKA_INSTANCE}_Credentials-1
    ibmcloud fn package delete data-processing-message-hub
    
    echo -e "Uninstall Complete"
}

function showenv() {
    echo -e KAFKA_INSTANCE="$KAFKA_INSTANCE"
    echo -e KAFKA_CREDS="$KAFKA_CREDS"
    echo -e SRC_TOPIC="$SRC_TOPIC"
    echo -e DEST_TOPIC="$DEST_TOPIC"
}

case "$1" in
    "--install" )
        ibmcloud_login
        install
    ;;
    "--uninstall" )
        ibmcloud_login
        uninstall
    ;;
    "--env" )
        showenv
    ;;
    * )
        usage
    ;;
esac
