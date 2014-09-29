# Backbone.Sails.Collection v0.1

***

* ## [Methods](#methods-1)

 * ### [`constructor/initialize([models], [options])`](#constructorinitializemodels-options-1)
 
 * ### [`.fetch([options])`](#fetchoptions-1)
 
 * ### [`.query([criteria])`](#querycriteria-1)
 
 * ### [`.subscribe()`](#subscribe-1)
 
* ## [Events](#events-1)

 * ### [`"created" (modelData, socketEvent)`](#created)
 
 * ### [`"socketSync" (collection, response, options)`](#socketsync)
  
 * ### [`"socketError" (collection, response, options)`](#socketerror)
  
 * ### [`"socketRequest" (collection, promise, options)`](#socketrequest)
  
 * ### [`"subscribed:collection" (collection, modelName)`](#subscribedcollection)
 
* ## [Events bubbled from `Backbone.Sails.Model`](#events-bubbled-from-backbonesailsmodel-1)

 * ### [`"addedTo" (model, socketEvent)`](#addedto)

 * ### [`"addedTo:attribute" (model, id, socketEvent)`](#addedtoattribute)
 
 * ### [`"removedFrom" (model, socketEvent)`](#removedfrom)
 
 * ### [`"removedFrom:attribute" (model, id, socketEvent)`](#removedfromattribute)
 
 * ### [`"destroyed" (model, socketEvent)`](#destroyed)
 
 * ### [`"updated" (model, socketEvent)`](#updated)
 
 * ### [`"updated:attribute" (model, value, socketEvent)`](#updatedattribute)
 
 * ### [`"messaged" (model, socketEvent)`](#messaged)
 
 * ### [`"socketSync" (model, response, options)`](#socketsync-1)
 
 * ### [`"socketError" (model, response, options)`](#socketerror-1)
 
 * ### [`"socketRequest" (model, promise, options)`](#socketrequest-1)
 
 * ### [`"subscribed:model" (model, modelName)`](#subscribedmodel)

***

# `Backbone.Sails.Collection`

### @type Object
### @extends `Backbone.Collection`
### @override `fetch, where`

`Backbone.Sails.Collection` is simply a `Backbone.Collection` that fires ordinary `Backbone` events as well as [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events originating from a Sails backend. The `fetch` method have been overridden to attempt to sync over socket's by default, delegating to [`sync`](http://backbonejs.org/#Model-sync) as configured (see the `socketSync` and `subscribe` configuration options).

The default [`model`](http://backbonejs.org/#Collection-model) of a `Backbone.Sails.Collection` is (naturally) a `Backbone.Sails.Model`. It'll work fine with any `Backbone.Model`.

## Methods

* ### `constructor/initialize([models], [options])`

 In addition to the [backbone configuration options](http://backbonejs.org/#Collection-constructor), you can pass the `socketSync` and `subscribe` options to the collection constructor.
 
 **@example**
 
 ```javascript
 var coll = new Backbone.Sails.Collection([], { socketSync: true })
 ```

* ### `fetch([options])`
 `fetch` performs much the [same](http://backbonejs.org/#Collection-fetch), however, you can specify filter and sort criteria for the resources to be fetched using the `query` method, before making any GET requests.
 
 You can pass the `socketSync` and `subscribe` options at the request level, as well as a `url` option. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

 **@params**

 * `[options]` You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `fetch` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `query([criteria])`
 `query` is a utility method to configure the query parameters sent to the server. For collections, it is used to configure the `populate`, `where`, `skip`, `sort` and `limit` query parameters when `fetch`'ing on this collection. `criteria` can be an object with these query parameters. Or, if `criteria` is not passed, `query()` will return a chainable query API with the methods `populate()`, `where()`, `skip()`, `sort()` and `limit()`.
 
 **@params**
 
 * `[criteria]`
 An object of query parameters.
 
 ```javascript
 collection.query({
   populate: "user",
   where: { name: { startsWith: "I" } }
 })
 collection.fetch()
 ```
 
 **@returns `queryAPI`**
 
 `queryAPI` has the following methods.
 
 * `populate([String|Array], [String]...)`
 
   `populate` specifies the attributes to be [populated](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) when requesting data from the server. It can be called with a single `String`, an `Array` of `String` or multiple `String` arguments:
 
   ```javascript
   coll.query().populate("address")
   coll.query().populate(["address", "employer"])
   coll.query().populate("address", employer")
   ```
  
 * `where({criteria})`
 
   `where` specifies the filter criteria for models returned. The criteria object will be passed straight into waterline's [`where`](https://github.com/balderdashy/waterline-docs/blob/master/query.md) on the server side, allowing you to easily filter the resources returned.
   
   ```javascript
   coll.query()..where({
     name: { contains: "I" }
   })
   ```
   
 * `skip(Number)`
 
   `skip` specifies the number of records to skip.
 
 * `limit(Number)`
 
   `limit` specifies the maximum number of records to return.
   
 * `sort(Object|String)`
 
   `sort` specifies how to sort the records returned. It can take a `String`: `createdAt`, `createdAt DESC`, `name ASC`. Or it can take an object describing the sort criteria (as per the [waterline](https://github.com/balderdashy/waterline-docs/blob/master/query.md) docs).
   
   ```javacript
   // sort by lastName ASC, and then firstName DESC
   coll.query().sort({
     lastName: 1
     firstName: 0
   })
   // sort by lastName ASC, and then firstName DESC
   coll.query().sort({
     lastName: "ASC"
     firstName: "DESC"
   })
   ```
   
 * `paginate(page, limit)`
 
   A convenience function for pagination of collections. `page` refer's to the page number. `limit` refers to the records per page.
   
* ### `subscribe()`
  `subscribe` will set up this collection to listen for socket based events from the relevant event aggregator. It is only necessary to call this when you have created a new collection instance for a Model that is known to be subscribed to (on the server) for the socket connected.
  
 **@returns `$.Deferred`**
 
 **@example**
   
 ```javascript
 var UserColl = new Backbone.Sails.Collection({ url: "/user" })
 var userCollOne = new UserColl();
 
 // this will *subscribe* this socket to `created` event on the '/user' Model
 userCollOne.fetch();
 
 // somewhere else in the app
 var userCollTwo = new UserColl()
 
 // we know this socket to be subscribed to '/user'
 // therefore we'll be receving `created` event's through the socket already
 // (provided the server side config is setup to do so)
 // so let's just subscribe our collection clientside
 userCollTwo.subscribe()
 
 userCollTwo.on("created", function(data){ // do stuff })
 ```


## Events
Events are where the magic happens. Many server-originated [resourceful pub/sub event's](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) are triggered on a *subscribed* collection, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your collection server-side**. The core ethos of this plugin was to get these event's on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

_You can prefix these event identifiers making use of the `eventPrefix` configuration option._

* ### `"created"`

 Triggered on your collection when a model resource is [`created`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html).

 **@params**
 * `data` A POJO representing the created resource. That is, a series of key-val attributes. *Not* a `Backbone.Model`.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html).
 

* ### `"socketSync"`

 Triggered on your collection when it is synced over the socket. This fire's at the same time as Backbone's [`sync`](http://backbonejs.org/#Events-catalog) event

 **@params**
 
 * `collection` The collection that has been synced over the socket.
 * `response` The response from the server.
 * `options` The options for the socket sync request.

* ### `"socketError"`

 Triggered on your collection when socket sync fails for some reason. This fire's at the same time as Backbone's [`error`](http://backbonejs.org/#Events-catalog) event.

 **@params**
 
 * `collection` The collection that hasn't been socket synced.
 * `response` The response from the server.
 * `options` The options for the socket sync request.

* ### `"socketRequest"`

 Triggered on your collection when a socket sync is requested. This fire's at the same time as Backbone's [`request`](http://backbonejs.org/#Events-catalog) event.

 **@params**
 
 * `collection` The collection that is requesting a socket sync.
 * `promise` A promise resolving the outcome of the socket sync.
 * `options` The options for the socket sync request.

* ### `"subscribed:collection"`

 Triggered on your collection when it is subscribed to it's resource event aggregator. 

 **@params**
 
 * `collection` The collection that has been subscribed.
 * `modelName` The name or _identifier_ of the model resource that has been subscribed. e.g. `user`

## Events bubbled from `Backbone.Sails.Model`
These events are bubbled from model's within the collection. 

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
 * `modelName` The name or _identifier_ of the model resource that has been subscribed. e.g. `user`.