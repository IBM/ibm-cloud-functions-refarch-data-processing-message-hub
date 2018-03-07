# Deploy using IBM Continuous Delivery

This deployment approach clones this repository under your own GitHub name and sets up an IBM Continuous Delivery toolchain that redeploys your application each time changes are pushed to your clone.

Supply your IBM Cloud Functions API key and [Service] credentials under the Delivery Pipeline icon, click Create, then run the Deploy stage in the resulting Delivery Pipeline.

You can then automatically redeploy changes by pushing changes to your cloned repository.

[![Deploy to the IBM Cloud](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/ibm-cloud-functions-refarch-data-processing-message-hub.git)