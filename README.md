# Serverless reference architecture for IBM Event Streams data processing with IBM Cloud Functions

[![Build Status](https://travis-ci.org/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.svg?branch=master)](https://travis-ci.org/IBM/ibm-cloud-functions-refarch-data-processing-message-hub)

This project deploys a reference architecture with IBM Cloud Functions to execute code in response to messages or to handle streams of data records. No code runs until messages arrive via IBM Event Streams (powered by Apache Kafka). When that happens, function instances are started and automatically scale to match the load needed to handle the stream of messages.

You can learn more about the benefits of building a serverless architecture for this use case in the accompanying [IBM Code Pattern](https://developer.ibm.com/code/patterns/respond-messages-handle-streams/).

Deploy this reference architecture:

- Through the [IBM Cloud Functions user interface](#deploy-through-the-ibm-cloud-functions-console-user-interface).
- Or by using [command line tools on your own system](#deploy-using-the-wskdeploy-command-line-tool).

If you haven't already, sign up for an IBM Cloud account then go to the [Cloud Functions dashboard](https://console.bluemix.net/openwhisk/) to explore other [reference architecture templates](https://github.com/topics/ibm-cloud-functions-refarch) and download command line tools, if needed.

## Included components

- [IBM Cloud Functions](https://cloud.ibm.com/openwhisk) (powered by Apache OpenWhisk)
- [IBM Event Streams](https://cloud.ibm.com/catalog/services/event-streams) (powered by Apache Kafka)

The application deploys two IBM Cloud Functions (based on Apache OpenWhisk) that read from and write messages to IBM Event Streams (based on Apache Kafka). This demonstrates how to work with data services and execute logic in response to message events.

One function, or action, is triggered by message streams of one or more data records. These records are piped to another action in a sequence (a way to link actions declaratively in a chain). The second action aggregates the message and posts a transformed summary message to another topic.

![Sample Architecture](img/refarch-data-processing-message-hub.png)

## Deploy through the IBM Cloud Functions console user interface

Choose "[Start Creating](https://console.bluemix.net/openwhisk/create)" and select "Deploy template" then "Event Streams Events" from the list. A wizard will then take you through configuration and connection to event sources step-by-step.

Behind the scenes, the UI uses the `wskdeploy` tool, which you can also use directly from the CLI by following the steps in the next section.

## Deploy using the `wskdeploy` command line tool

This approach will deploy the Cloud Functions actions, triggers, and rules using the runtime-specific manifest file available in this repository.

### Download CLI tools

- Download the latest [`ibmcloud` CLI and Cloud Functions plugin](https://cloud.ibm.com/openwhisk/learn/cli).
- Download the latest [`wskdeploy` CLI](https://github.com/apache/incubator-openwhisk-wskdeploy/releases).
### Provision Event Streams instance

- Provision an [IBM Event Streams](https://cloud.ibm.com/catalog/services/event-streams) instance and name it `kafka-broker`.  

*You can use the [web console](https://cloud.ibm.com/catalog/services/event-streams) to create the instance or the CLI with a command like:*

```
ibmcloud service create messagehub standard kafka-broker
```
### Create Event Streams credentials

- Create new service credentials for the `kafka-broker` instance named  _kafka-credentials_.

This can be achieved using the "Service credentials" tab on the service instance web page in IBM Cloud or using the IBM Cloud CLI with the following command.

```
ibmcloud service key-create kafka-broker kafka-credentials
```

### Create message topics

- From the "Manage" tab on the Event Streams instance page in IBM Cloud, create the following topics:
  - _in-topic_ 
  - _out-topic_

- Copy `template.local.env` to a new file named `local.env` and update the `KAFKA_INSTANCE`, `SRC_TOPIC`, and `DEST_TOPIC` values for your instance if they differ.

### Deploy with `wskdeploy`

```bash
# Clone a local copy of this repository
git clone https://github.com/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.git
cd ibm-cloud-functions-refarch-data-processing-message-hub

# Make service credentials available to your environment
source local.env
ibmcloud fn package refresh

# Deploy the packages, actions, triggers, and rules using your preferred language
cd runtimes/nodejs # Or runtimes/[php|python|swift]
wskdeploy
```

### Undeploy with `wskdeploy`

```bash
# Deploy the packages, actions, triggers, and rules
wskdeploy undeploy
```

## Testing with example messages

- Run the following command to poll for activations logs

```
ibmcloud wsk activation poll
```

- Send a test message to the input topic using the package action.

```
$ DATA=$( base64 events.json | tr -d '\n' | tr -d '\r' )
$ ibmcloud wsk action invoke Bluemix_${KAFKA_INSTANCE}_${KAFKA_CREDS}/messageHubProduce \
  --param topic $SRC_TOPIC \
  --param value "$DATA" \
  --param base64DecodeValue true
```

- Review the output from the activation polling command to see the activation events from the trigger and actions.

```
Activation: 'transform-produce' (76b37762ec28417bb37762ec28317b43)
...
Activation: 'receive-consume' (ee0423e3c9d742918423e3c9d7329147)
...
Activation: 'message-processing-sequence' (4adcd36bf44b4cf39cd36bf44bfcf32f)
...
Activation: 'message-trigger' (8886c1ff06a04d4d86c1ff06a07d4d76)
...
Activation: 'messageHubProduce' (431bb7acb23e4cd99bb7acb23e2cd94c)
```

## Alternative deployment methods

### Deploy manually with the `ibmcloud fn` command line tool

[This approach shows you how to deploy individual the packages, actions, triggers, and rules with CLI commands](bx-wsk/README.md). It helps you understand and control the underlying deployment artifacts.

### Deploy with IBM Continuous Delivery

[This approach sets up a continuous delivery pipeline that redeploys on changes to a personal clone of this repository](bx-cd/README.md). It may be of interest to setting up an overall software delivery lifecycle around Cloud Functions that redeploys automatically when changes are pushed to a Git repository.

## License

[Apache 2.0](LICENSE)
