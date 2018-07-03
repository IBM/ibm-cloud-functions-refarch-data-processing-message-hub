#!/bin/bash

##############################################################################
# Copyright 2018 IBM Corporation
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
set -e

# Write the Cloud Functions specific values to .wskprops
echo "APIHOST=$APIHOST" > "$HOME/.wskprops"
echo "NAMESPACE=$NAMESPACE" >> "$HOME/.wskprops"
echo "APIVERSION=$APIVERSION" >> "$HOME/.wskprops"
echo "AUTH=$AUTH" >> "$HOME/.wskprops"
echo "APIGW_ACCESS_TOKEN=$APIGW_ACCESS_TOKEN" >> "$HOME/.wskprops"

# Download IBM Cloud CLI and Cloud Functions plugin (already in the build container)
curl -fsSL https://clis.ng.bluemix.net/install/linux | sh
bx plugin install Cloud-Functions -r Bluemix -f
bx api https://api.ng.bluemix.net
bx login -u $BX_USERNAME -p "$BX_PASSWORD" -o $BX_USERNAME -s refarch

# Download the wskdeploy CLI
curl -OL https://github.com/apache/incubator-openwhisk-wskdeploy/releases/download/latest/openwhisk_wskdeploy-latest-linux-amd64.tgz
tar xf openwhisk_wskdeploy-latest-linux-amd64.tgz
chmod 755 wskdeploy

# Make service credentials available to your environment
bx wsk package refresh

# Deploy the packages, actions, triggers, and rules starting from a clean slate
mv wskdeploy runtimes/nodejs/
cd runtimes/nodejs # Or runtimes/[php|python|swift]
./wskdeploy

# Test after installing prereqs
sudo apt-get update
sudo apt-get install jq

../../travis/kafka_publish.sh

sleep 5

CONSUME_OUTPUT=`../../travis/kafka_consume.sh`

KAFKA_MESSAGE=`echo "$CONSUME_OUTPUT" | tail -3 | head -1`

echo "$CONSUME_OUTPUT"
echo "$KAFKA_MESSAGE"

MSG_AGENT=`echo $KAFKA_MESSAGE | jq -r '.agent'`
if [[ $MSG_AGENT == "IBM Cloud Function action" ]]
then
	echo "Found the message we were expecting"
    ./wskdeploy undeploy
else
	echo "Something went wrong"
	./wskdeploy undeploy
	exit -1
fi

