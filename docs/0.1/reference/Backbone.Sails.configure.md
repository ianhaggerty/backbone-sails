# Backbone.Sails.configure v0.1

***

# `Backbone.Sails.configure(options)`
## @type Function

This function configures various global options for using `Backbone.Sails`. Call it before instantiating any models/collections.

## Configuration options

These options are available to configure on the `options` object.

* ### `eventPrefix`

 String to prefix all `Backbone.Sails` event's on `Backbone.Sails.Model`, `Backbone.Sails.Collection` and their derivatives.
 
 **@defaultsTo** `""`

* ### `findSocketClient()`

 This function will be invoked internally when the implementation needs to find the socket client. The function should return the socket client (typically at `io.socket`) or undefined.
 
 **@defaultsTo** `function(){}`

* ### `connectToSocket(socketClient)`

 This function will be invoked internally when the implementation needs to connect to the socket. Useful if your app has specialized collection logic. No return required. Socketclient (io.socket) will be passed as first argument.
 
 **@defaultsTo** `function(socketClient){}`

* ### `subscribe`

 `Backbone.Sails.Model`'s and `Backbone.Sails.Collection`'s are, by default, automatically setup to delegate to jqXHR requests if web sockets is unavailable. However - these requests do not subscribe the socket connected to the [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events.
 
 The `subscribe` option is a boolean indicating whether to re-send these requests over web-sockets, to ensure the socket connected is subscribed to receive [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events for the model/collection being synced. All socket requests resent are as 'read' requests. All requests re-sent over sockets will be sent as `read` requests - and they may update the state of the model/collection on the clientside (`Backbone` will call `set`, as it does with `fetch`) when they are sent.
 
 **@defaultsTo** `true`

* ### `socketSync`

 This is a boolean indicating whether to send all requests over sockets. If the socket is unavailable or disconnected, then the implementation will wait for the socket to connect before attempting to send the request again.
 
 **@defaultsTo** `false`
 
 _Both `socketSync` and `subscribe` can be passed as options to a model/collection constructor. They can also be passed as request specific options to methods such as `fetch`._

* ### `timeout(defer)`

 `timeout` is a function that determines how long to wait before reattempting to resolve a `$.Deferred` within the implementation. This is typically used to control how often to try to reconnect, for example. `timeout` should return the delay before attempting to resolve again, otherwise a falsy return value indicates to cease trying altogether.
 
 **@defaultsTo**
 ```javascript
 function(defer){
  if !defer.attempts
   defer.attempts = 1
  else
   defer.attempts += 1
 
  if defer.attempts <= 5
   return 150
  else if defer.attempts <= 10
   return 500
  else if defer.attempts <= 50
   return 1000
  else if defer.attempts <= 100
   return 4000
  else
   return false
 }
 ```

* ### `query`

 `query` is an object that determines the default filter criteria for `Backbone.Sails.Collection`'s. These are usually configured at the collection level using methods such as `coll.query().skip(2)`, however you can pass some global default values in here.
 
 **@defaultsTo**
 ```javascript
 {
 where: ''
 limit: 30
 sort: ''
 skip: 0
 }
 ```
