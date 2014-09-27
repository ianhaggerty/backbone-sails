# Backbone.Sails.Model v0.1

***

# `Backbone.Sails.Model`

### @type Object
### @extends `Backbone.Model`
### @override `fetch, save, destroy`

`Backbone.Sails.Model` is simply a `Backbone.Model` that fires ordinary `Backbone` events as well as events originating from server side changes to the resource referenced via the `url` (property or function). In order to achieve this, the usual `save` and `fetch` methods have been completely rewritten to make use of the networking internals of `Backbone.Sails` according to the configuration (see `socketSync` and `subscribe` properties of `Backbone.Sails.configure`). Furthermore, if the `socketSync` configuration option is `false`, in the event of a socket not being available, `Backbone.Sails` will delegate to whatever `sync` function is found on the model (usually just `Backbone.sync`).

## Methods

* ### `save([attrs[key, val]], [options])`
 `Save` works just as before - it attempts to persist your model server-side. It will sync over web sockets if available. If web sockets aren't available, if `socketSync` is false, it will delegate to `model.sync`, and, if `subscribe` is true, it will wait for the socket to become available before sending another `read` request down the socket to subscribe the resource server side. If `socketSync` is true, it will wait for the socket to become available without ever delegating to `model.sync`.

 **@params**
 * `[attrs]`
    A set of key-value to be persisted onto the model resource. (No change from [Backbone](http://backbonejs.org/#Model-save))

 * `[key, val]`
    Instead of passing a set of key-value pairs, you can just pass one making use of the first two arguments. (Again, no change from [Backbone](http://backbonejs.org/#Model-save), though this usage isn't documented)

 * `[options]`
    You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `save` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `fetch(attrs[key, val], [options])`
 `Fetch` works just as before - it attempts to fetch the server-side state of your model. It will sync over web sockets if available. If web sockets aren't available, if `socketSync` is false, it will delegate to `$.ajax` (`Backbone.sync`), and, if `subscribe` is true, it will wait for the socket to become available before sending another `read` request down the socket to subscribe the resource server side. If `socketSync` is true, it will wait for the socket to become available.

 **@params**

 * `[options]`
 You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `fetch` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `destroy([options])`
 `Destroy` works just as before - it sends a `DELETE` request to the server to delete the model resource. It will sync over web sockets if available. If web sockets aren't available, it will delegate to `$.ajax` (`Backbone.sync`). If `socketSync` is true, it will wait for the socket to become available.

 **@params**

 * `[options]`
 You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.destroy](http://backbonejs.org/#Model-destroy)). You can override the `socketSync` configuration option on a per request basis.

 **@returns `$.Deferred`**
 
 `destroy` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `query([criteria])`
 `query` is a utility method to configure the query parameters sent to the server. For models, it is used to configure the `populate` option when `fetch`'ing on this model. `criteria` can be an object with a `populate` option. Or, if `criteria` is not passed, `query()` will return a chainable query API with the methods `populate`. The `populate` options can be an array, or a string. When calling `populate` from the chainable query API, you can also call it with multiple arguments, each a string representing what you'd like to populate.

 **@example**

```javascript
model.query({
  populate: "user"
})
model.query({
  populate: ["user", "message"]
})
model.query().populate("user")
model.query().populate(["user", "message"])
model.query().populate("user", "message")
```

## Events
Events is where the magic happens. Many server-originated socket based event's are triggered on a *subscribed* model, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your model server-side**. The core ethos of this plugin was to get these event's happening on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

_You can prefix these event identifiers making use of the `eventPrefix` configuration option._

* ### `"addedTo"`

 Triggered on your model when an association is [`addedTo`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html)

 **@params**
 * `model` The model that has been added to.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).

* ### `"addedTo:attribute"`

 Triggered on your model when an association is [`addedTo`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html). `attribute` in the event identifier, refers to the name of the attribute that was added to (e.g. `users`, `owner`).

 **@params**
 * `model` The model that has been added to.
 * `id` The id of the _model that was added_.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).

* ### `"removedFrom"`

 Triggered on your model when an association is [`removedFrom`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html)

 **@params**
 * `model` The model that has been removed from.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).

* ### `"removedFrom:attribute"`

 Triggered on your model when an association is [`removedFrom`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html). `attribute` in the event identifier, refers to the name of the attribute that was removed from (e.g. `users`).

 **@params**
 * `model` The model that has been removed from.
 * `id` The id of the _model that was removed_.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).

* ### `"destroyed"`

 Triggered on your model when the resource it refers to is [destroyed](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html). That is, the resource has been deleted server side. **Note**, there is a very similar backbone event `destroy`. This refer's to the model method `destroy` being invoked and (typically) sending a `DELETE` request.

 **@params**
 * `model` The model that has been destroyed (server side at least).
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).

* ### `"updated"`

 Triggered on your model when the resource it refers to is [updated](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishUpdate.html).

 **@params**
 * `model` The model that has been updated.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).

* ### `"updated:attribute"`

 Triggered on your model when the resource it refers to is [updated](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishUpdate.html).

 **@params**
 * `model` The model that has been updated.
 * `value` The new value of the attribute.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).

* ### `"messaged"`

 Triggered on your model when the resource it refers to is [messaged](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).

 **@params**
 * `model` The model that has been messaged.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).


* ### `"socketSync"`

 Triggered on your model when it is synced over the socket. This fire's at the same time as Backbone's [`sync`](http://backbonejs.org/#Events-catalog) event

 **@params**
 * `model` The model that has been synced over the socket.
 * `response` The response from the server.
 * `options` The options for the socket sync request.

* ### `"socketError"`

 Triggered on your model when socket sync fails for some reason. This fire's at the same time as Backbone's [`error`](http://backbonejs.org/#Events-catalog) event.

 **@params**
 * `model` The model that hasn't been socket synced.
 * `response` The response from the server.
 * `options` The options for the socket sync request.

* ### `"socketRequest"`

 Triggered on your model when a socket sync is requested. This fire's at the same time as Backbone's [`request`](http://backbonejs.org/#Events-catalog) event.

 **@params**
 * `model` The model that is requesting a socket sync..
 * `promise` A promise resolving the outcome of the socket sync.
 * `options` The options for the socket sync request.

* ### `"subscribed:model"`

 Triggered on your model when it is subscribed to it's model resource event aggregator. 

 **@params**
 * `model` The model that has been subscribed.
 * `modelName` The name or _identifier_ of the model resource that has been subscribed. e.g. `user`