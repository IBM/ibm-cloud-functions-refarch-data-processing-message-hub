/*
 * Copyright 2017-2018 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var openwhisk = require('openwhisk');

/**
 * Analyze incoming message and generate a summary as a response
 */
function transform(events) {
  var average = 0;
  for (var i = 0; i < events.length; i++) {
    average += events[i].payload.velocity;
  }
  average = average / events.length;
  var result = {
    "agent": "IBM Cloud Function action",
    "events_count": events.length,
    "avg_velocity": average
  };
  return result;
}

/**
 * Process incoming message from the receive-consume action earlier
 * in the sequence and publish a new message to Message Hub.
 */
function main(params) {
  console.log("DEBUG: Received message as input: " + JSON.stringify(params));

  return new Promise(function (resolve, reject) {
    if (!params.topic || !params.kafka || !params.events || !params.events[0]) {
      reject("Error: Invalid arguments. Must include topic, events[], kafka service name.");
    }

    var transformedMessage = JSON.stringify(transform(params.events));
    console.log("DEBUG: Message to be published: " + transformedMessage);

    openwhisk().actions.invoke({
      name: 'Bluemix_' + params.kafka + '_Credentials-1/messageHubProduce',
      blocking: true,
      result: true,
      params: {
        value: transformedMessage,
        topic: params.topic
      }
    }).then(result => {
      resolve({
        "result": "Success: Message was sent to IBM Message Hub."
      });
    }).catch(error => {
      reject(error);
    });

  });
}
