# Deploy using IBM Continuous Delivery

This deployment approach clones this repository under your own GitHub name and sets up an IBM Continuous Delivery toolchain that redeploys your application each time changes are pushed to your clone.

First, provision an [IBM Message Hub](https://console.ng.bluemix.net/catalog/services/message-hub) instance, and name it `kafka-broker`. On the "Manage" tab of your Message Hub console create two topics: _in-topic_ and _out-topic_. On the "Service credentials" tab make sure to add a new credential named _Credentials-1_.

Then click the button below and supply your IBM Cloud Functions API key and Message Hub credentials under the Delivery Pipeline icon, click Create, then run the Deploy stage in the resulting Delivery Pipeline.

You can then automatically redeploy changes by pushing changes to your cloned repository.

[![Deploy to the IBM Cloud](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.git)