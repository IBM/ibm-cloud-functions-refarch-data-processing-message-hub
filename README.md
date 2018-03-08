# Serverless reference architecture for IBM Message Hub data processing with IBM Cloud Functions

[![Build Status](https://travis-ci.org/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.svg?branch=master)](https://travis-ci.org/IBM/ibm-cloud-functions-refarch-data-processing-message-hub)

This project shows how serverless, event-driven architectures execute code in response to messages or to handle streams of data records. No code runs until messages arrive on the IBM Message Hub (powered by Apache Kafka) topic. When that happens, application instances are started to match the load needed by the stream of messages exactly.

In addition to using cloud resources efficiently, this means that developers can build and deploy applications more quickly. You can learn more about the benefits of building a serverless architecture for this use case in the accompanying [IBM Code Pattern](https://developer.ibm.com/code/patterns/respond-messages-handle-streams/).

Deploy this reference architecture:

- Through the [IBM Cloud Functions user interface](#deploy-through-the-ibm-cloud-functions-console-user-interface).
- Or by using [command line tools on your own system](#deploy-using-the-wskdeploy-command-line-tool).

If you haven't already, sign up for an IBM Cloud account and go to the [Cloud Functions dashboard](https://console.bluemix.net/openwhisk/) to explore other [reference architecture templates](https://github.com/topics/ibm-cloud-functions-refarch) and download command line tools, if needed.

## Included components

- IBM Cloud Functions (powered by Apache OpenWhisk)
- IBM Message Hub (powered by Apache Kafka)

The application demonstrates two IBM Cloud Functions (based on Apache OpenWhisk) that read and write messages with IBM Message Hub (based on Apache Kafka). The use case demonstrates how actions work with data services and execute logic in response to message events.

One function, or action, is triggered by message streams of one or more data records. These records are piped to another action in a sequence (a way to link actions declaratively in a chain). The second action aggregates the message and posts a transformed summary message to another topic.

![Sample Architecture](img/refarch-data-processing-message-hub.png)

## Deploy through the IBM Cloud Functions console user interface

Choose "[Start Creating](https://console.bluemix.net/openwhisk/create)" and select "Deploy template" then "Message Hub Events" from the list. A wizard will then take you through configuration and connection to event sources step-by-step.

Behind the scenes, the UI uses `wskdeploy`, which you can also use directly from the CLI by following the steps in the next section.

## Deploy using the `wskdeploy` command line tool

This approach will deploy the Cloud Functions actions, triggers, and rules using the runtime-specific manifest file available in this repository.

- Download the latest [`bx` CLI and Cloud Functions plugin](https://console.bluemix.net/openwhisk/learn/cli).
- Download the latest [`wskdeploy` CLI](https://github.com/apache/incubator-openwhisk-wskdeploy/releases).
- Provision an [IBM Message Hub](https://console.ng.bluemix.net/catalog/services/message-hub) instance, and name it `kafka-broker`. On the "Manage" tab of your Message Hub console create two topics: _in-topic_ and _out-topic_. On the "Service credentials" tab make sure to add a new credential named _Credentials-1_.
- Copy `template.local.env` to a new file named `local.env` and update the `KAFKA_INSTANCE`, `SRC_TOPIC`, and `DEST_TOPIC` values for your instance if they differ.

### Deploy

```bash
# Clone a local copy of this repository
git clone https://github.com/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.git
cd ibm-cloud-functions-refarch-data-processing-message-hub

# Make service credentials available to your environment
source local.env
bx wsk package refresh

# Deploy the packages, actions, triggers, and rules using your preferred language
cd runtimes/nodejs # Or runtimes/[php|python|swift]
wskdeploy
```

### Undeploy

```bash
# Deploy the packages, actions, triggers, and rules
wskdeploy undeploy
```

## Alternative deployment methods

### Deploy manually with the `bx wsk` command line tool

[This approach shows you how to deploy individual the packages, actions, triggers, and rules with CLI commands](bx-wsk/README.md). It helps you understand and control the underlying deployment artifacts.

### Deploy with IBM Continuous Delivery

[This approach sets up a continuous delivery pipeline that redeploys on changes to a personal clone of this repository](bx-cd/README.md). It may be of interest to setting up an overall software delivery lifecycle around Cloud Functions that redeploys automatically when changes are pushed to a Git repository.

## License

[Apache 2.0](LICENSE)
