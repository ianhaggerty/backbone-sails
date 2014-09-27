# Backbone.Sails.configure v0.1


***


# `Backbone.Sails.configure`
### @type Function

Configures the internal configuration object.

### @params
* `[options]` Configuration options.
 * `[eventPrefix=""]` String to prefix all `Backbone.Sails` event's on `Backbone.Sails.Model`, `Backbone.Sails.Collection` and their derivatives.
 * `[interval=500]` In a nutshell, the amount of time before `Backbone.Sails` make's another attempt at resolving a promise. It is used internally to determine when to try certain actions again.
 * `[attempts=20]` The number of attempts to make a certain action before `Backbone.Sails` give's up! Set to a finite number to avoid indefinite polling. Set to undefined make attempts indefinitely (not recommended).
 * `[findSocketClient=function(){}]` This function will be invoked internally when the implementation needs to find the socket client. The function should return the socket client (typically at `io.socket`) or undefined.
 * `[connectToSocket=function(socketClient){}]` This function will be invoked internally when the implementation needs to connect to the socket. Useful if your app has specialized collection logic. No return required. Socketclient (io.socket) will be passed as first argument.
 * `[subscribe=true]` `Backbone.Sails.Model`'s and `Backbone.Sails.Collection`'s are, by default, automatically setup to delegate to jqXHR requests if web sockets is unavailable. However - these requests do not subscribe the socket to the [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events. The `subscribe` option is a boolean indicating whether to re-send these requests over web-sockets, to ensure the model/collection is subscribed, when it becomes available. All socket requests resent are as 'read' requests. This means that if the state of the resource on the server has changed since the jqXHR request, your `Backbone.Sails.Model`'s and `Backbone.Sails.Collection`'s may trigger `add remove change` events on your when `Backbone` calls `set`. **Bare this in mind** when designing an app to take advantage of this delegation. This option can be overridden on a per request basis via the `options` parameter you'll be familiar with from Backbone already.
  * `[socketSync=false]` Boolean indicating whether to send all requests over sockets. If socket is unavailable or disconnected, then the implementation will wait for the socket connect (according to the `interval` and `attempts` configuration options, basically it'll timeout in `interval * attempts` milliseconds).
  * `[defaults={ where: {}, limit: 30, sort: {}, skip: 0 }]` The default query parameters for a `Backbone.Sails.Collection`. Used to filter the records returned from `fetch` and `subscribe`.
