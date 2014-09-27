# Backbone.Sails v0.1

***

# `Backbone.Sails`
### @type Object
### @extends `Backbone.Events`

Used internally to track the state of the application.

### Events
* ### `"register:collection"`
 Emitted when a collection is 'registered' client side. This refers to the process of registering an event aggregator at `Backbone.Sails.Collection.eventIdentifier` and setting up a socket listener to forward relevant events to the event aggregator.

 **@params**
 * `eventIdentifier` The event identifier originally from the SailsJS backend. This is almost always just the name of the model on the server. e.g. `user`. Refer to [io.socket.on](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/io.socket.on.html) for details.
 * `eventAggregator` The event aggregator registered client side. Found at `Backbone.Collections.eventIdentifier`.

* ### `"register:model"`
 Emitted when a model is 'registered' client side. This refers to the process of registering an event aggregator at `Backbone.Sails.Models.eventIdentifier.modelId` and setting up a socket listener to forward relevant events to the event aggregator.

 **@params**
 * `eventIdentifier` The event identifier originally from the SailsJS backend. This is almost always just the name of the model on the server. e.g. `user`. Refer to [io.socket.on](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/io.socket.on.html) for details.
 * `eventAggregator` The event aggregator registered client side. Found at `Backbone.Models.modelId.eventIdentifier`.
  
* ### `"connected"`
 Triggered when socket connected. Forwarded from [sails.io.js](https://github.com/balderdashy/sails.io.js).

* ### `"disconnected"`
 Triggered when socket disconnected. Forwarded from [sails.io.js](https://github.com/balderdashy/sails.io.js).
