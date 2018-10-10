# Deploy step-by-step with the `ibmcloud` command line tool

## Prerequisites

You should have a basic understanding of the Cloud Functions/OpenWhisk programming model. If not, [try the action, trigger, and rule demo first](https://github.com/IBM/openwhisk-action-trigger-rule).

Also, you'll need an IBM Cloud account and the latest [`ibmcloud` command line tool with the Cloud Functions plugin installed and on your PATH](https://console.bluemix.net/openwhisk/learn/cli).

As an alternative to this end-to-end example, you might also consider the more [basic "building block" version](https://github.com/IBM/ibm-cloud-functions-message-hub-trigger) of this sample.

## Steps

1. [Configure IBM Event Streams](#1-configure-ibm-message-hub)
2. [Create IBM Cloud Functions actions, triggers, and rules](#2-create-ibm-cloud-functions-actions-triggers-and-rules)
3. [Test new message events](#3-test-new-message-events)
4. [Delete actions, triggers, and rules](#4-delete-actions-triggers-and-rules)
5. [Recreate deployment manually](#5-recreate-deployment-manually)

## 1. Configure IBM Event Streams

Log into the IBM Cloud, provision a [Event Streams](https://console.bluemix.net/catalog/services/event-streams) instance, and name it `kafka-broker`. On the "Manage" tab of your Events Streams console create two topics: _in-topic_ and _out-topic_. On the "Service credentials" tab make sure to add a new credential named _Credentials-1_.

Copy `template.local.env` to a new file named `local.env` and update the `KAFKA_INSTANCE`, `SRC_TOPIC`, and `DEST_TOPIC` values for your instance if they differ.

## 2. Create IBM Cloud Functions actions, triggers, and rules

`deploy.sh` is a convenience script reads the environment variables from `local.env` and creates the OpenWhisk actions, triggers, and rules on your behalf. Later you will run the commands from that file directly to understand how it works step-by-step.

```bash
cd ibmcloud-wsk
ibmcloud login -a api.ng.bluemix.net -o "$YOUR_ORG" -s "$YOUR_SPACE"
./deploy.sh --install
```

> **Note**: If you see any error messages, refer to the [Troubleshooting](#troubleshooting) section below.

## 3. Test new message events

Open one terminal window to poll the logs:

```bash
ibmcloud wsk activation poll
```

Send a message with a set of events to process.

```bash
# Produce a message, will trigger the sequence of actions
DATA=$( base64 ../events.json | tr -d '\n' | tr -d '\r' )

ibmcloud wsk action invoke Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubProduce \
  --param topic $SRC_TOPIC \
  --param value "$DATA" \
  --param base64DecodeValue true
```

## 4. Delete actions, triggers, and rules

Use `deploy.sh` again to tear down the OpenWhisk actions, triggers, and rules. You will recreate them step-by-step in the next section.

```bash
./deploy.sh --uninstall
```

## 5. Recreate deployment manually

This section provides a deeper look into what the `deploy.sh` script executes so that you understand how to work with OpenWhisk triggers, actions, rules, and packages in more detail.

### 5.1 Create Kafka message trigger

Create the `message-trigger` trigger using the Event Streams packaged feed that listens for new messages. The package refresh will make the Event Streams service credentials and connection information available to OpenWhisk.

```bash
ibmcloud wsk package refresh
ibmcloud wsk trigger create message-trigger \
  --feed Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubFeed \
  --param isJSONData true \
  --param topic ${SRC_TOPIC}
```

### 5.2 Create action to consume message

Upload the `receive-consume` action as a JavaScript action. This downloads messages when they arrive via the trigger.

```bash
ibmcloud wsk package create data-processing-message-hub
ibmcloud wsk action create data-processing-message-hub/receive-consume ../runtimes/nodejs/actions/receive-consume.js
```

### 5.3 Create action to aggregate and send back message

Upload the `transform-produce` action. This aggregates information from the action above, and sends a summary JSON string back to another Event Streams topic.

```bash
ibmcloud wsk action create data-processing-message-hub/transform-produce ../runtimes/nodejs/actions/transform-produce.js \
  --param topic ${DEST_TOPIC} \
  --param kafka ${KAFKA_INSTANCE}
```

### 5.4 Create sequence that links get and post actions

Declare a linkage between the `receive-consume` and `transform-produce` in a sequence named `message-processing-sequence`.

```bash
ibmcloud wsk action create data-processing-message-hub/message-processing-sequence \
  --sequence data-processing-message-hub/receive-consume,data-processing-message-hub/transform-produce
```

### 5.5 Create rule that links trigger to sequence

Declare a rule named `message-rule` that links the trigger `message-trigger` to the sequence named `message-processing-sequence`.

```bash
ibmcloud wsk rule create message-rule message-trigger data-processing-message-hub/message-processing-sequence
```

### 5.6 Test new message events

```bash
# Produce a message, will trigger the sequence
DATA=$( base64 ../events.json | tr -d '\n' | tr -d '\r' )

ibmcloud wsk action invoke Bluemix_${KAFKA_INSTANCE}_Credentials-1/messageHubProduce \
  --param topic $SRC_TOPIC \
  --param value "$DATA" \
  --param base64DecodeValue true
```

## Troubleshooting

Check for errors first in the OpenWhisk activation log. Tail the log on the command line with `ibmcloud wsk activation poll` or drill into details visually with the [monitoring console on the IBM Cloud](https://console.ng.bluemix.net/openwhisk/dashboard).

If the error is not immediately obvious, make sure you have the [latest version of the `ibmcloud` CLI installed](https://console.ng.bluemix.net/openwhisk/learn/cli). If it's older than a few weeks, download an update.

```bash
ibmcloud wsk property get --cliversion
```
