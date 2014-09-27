# Backbone.Sails.Collection v0.1

***

# `Backbone.Sails.Collection`

### @type Object
### @extends `Backbone.Collection`
### @override `fetch, where`

`Backbone.Sails.Collection` is simply a `Backbone.Collection` that fires ordinary `Backbone` events as well as events originating from server side changes to the resource referenced via the `url` (property or function). In order to achieve this, the `fetch` methods has been completely rewritten to make use of the networking internals of `Backbone.Sails` according to the configuration (see `socketSync` and `subscribe` properties of `Backbone.Sails.configure`). If the `socketSync` configuration option is `false`, in the event of a socket not being available, `Backbone.Sails` will delegate to `collection.sync`.

## Methods

* ### `fetch([options])`
 `Fetch` works just as before - it attempts to fetch the server-side state of your collection. It will sync over web sockets if available. If web sockets aren't available, if `socketSync` is false, it will delegate to `collection.sync`, and, if `subscribe` is true, it will wait for the socket to become available before sending another `read` request down the socket to subscribe the resource server side. If `socketSync` is true, it will wait for the socket to become available.

 **@params**

 * `[options]` You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `save` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

## Filter Query Methods

* ### `where(Object criteria)`
 **@chainable**

 `where` configures the filter criteria for future `read` requests for this collection. The `options` parameter is passed straight into [waterline](https://github.com/balderdashy/waterline-docs). The criteria available for `where` is documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md). e.g. 

 `coll.where({ name: { startsWith: 'I' }}).fetch({ success: function(res){ // res is array of data } })`

* ### `sort(String|Object criteria)`
 **@chainable**

 `sort` configures the sort criteria for future `read` requests for this collection. The argument passed is sent straight into [waterline](https://github.com/balderdashy/waterline-docs). The criteria available for `sort` is documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md). e.g.

 `coll.sort({ name: 1, age: 0 }).fetch({ success: function(res){ // res is array of data } })`

 **@params**
 * `criteria` The filter criteria as documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).

* ### `skip(Number skip)`
 **@chainable**

 `skip` configures the skip criteria for future `read` requests for this collection. The argument passed is sent straight into [waterline](https://github.com/balderdashy/waterline-docs). The criteria available for `skip` is documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).

 **@params**
 * `skip` The number of results to skip.

* ### `limit(Number limit)`
 **@chainable**

 `limit` configures the limit criteria for future `read` requests for this collection. The argument passed is sent straight into [waterline](https://github.com/balderdashy/waterline-docs). The criteria available for `limit` is documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).

 **@params**
 * `limit` The number of results to limit to.

* ### `paginate(Number page, Number limit)`
 **@chainable**

 `paginate` is a utility method for paginating 'read' requests made to the server. It simply sets the relevant `skip` and `sort` criteria.

 **@params**
 * `page` The number of page to paginate to.
 * `limit` The number of results to limit to per page.


***

## Events
Events is where the magic happens. Many server-originated socket based event's are triggered on a *subscribed* collection, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your collection server-side**. The core ethos of this plugin was to get these event's happening on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look...

* ### `"created"`

 Triggered on your collection when a model resource is [`created`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html). This is the only collection specific event.

 **@params**
 * `model` The model that has been created. The type of the model will be `collection.model`.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html).

* ### `"addedTo"`
 
 **@bubbles from `Backbone.Model`**

 Triggered on your model when an association is [`addedTo`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html)

 **@params**
 * `model` The model that has been added to.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).

* ### `"addedTo:attribute"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when an association is [`addedTo`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html). `attribute` in the event identifier, refers to the name of the attribute that was added to (e.g. `users`, `owner`).

 **@params**
 * `model` The model that has been added to.
 * `id` The id **of the model that was added**.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).

* ### `"removedFrom"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when an association is [`removedFrom`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html)

 **@params**
 * `model` The model that has been removed from.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).

* ### `"removedFrom:attribute"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when an association is [`removedFrom`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html). `attribute` in the event identifier, refers to the name of the attribute that was removed from (e.g. `users`).

 **@params**
 * `model` The model that has been removed from.
 * `id` The id **of the model that was removed**.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).

* ### `"destroyed"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when the resource it refers to is [destroyed](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html). That is, the resource has been deleted server side. **Note**, there is a very similar backbone event `destroy`. This refer's to the model method `destroy` being invoked and (typically) sending a `DELETE` request.

 **@params**
 * `model` The model that has been destroyed (server side at least).
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).

* ### `"updated"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when the resource it refers to is [updated](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishUpdate.html).

 **@params**
 * `model` The model that has been updated.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).

* ### `"updated:attribute"`

 **@bubbles from `Backbone.Model`**

 Triggered on your model when the resource it refers to is [updated](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishUpdate.html).

 **@params**
 * `model` The model that has been updated.
 * `value` The new value of the attribute.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishDestroy.html).