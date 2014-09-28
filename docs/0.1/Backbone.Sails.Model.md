# Backbone.Sails.Model v0.1

***

* ## [Methods](#methods-1)

 * ### [`constructor/initialize([attrs], [options])`](#constructorinitializeattrs-options-1)

 * ### [`.save([attrs[key, val]], [options])`](#saveattrskey-val-options-1)
 
 * ### [`.fetch(attrs[key, val], [options])`](#fetchattrskey-val-options-1)
 
 * ### [`.destroy([options])`](#destroyoptions-1)
 
 * ### [`.query([criteria])`](#querycriteria-1)
 
 * ### [`.addTo(key, model [,options])`](#addtokey-model-options-1)
 
 * ### [`.removeFrom(key, model [,options])`](#removefromkey-model-options-1)
 
 * ### [`.subscribe()`](#subscribe-1)
 
* ## [Events](#events-1)

 * ### [`"addedTo" (model, socketEvent)`](#addedto)

 * ### [`"addedTo:attribute" (model, id, socketEvent)`](#addedtoattribute)
 
 * ### [`"removedFrom" (model, socketEvent)`](#removedfrom)
 
 * ### [`"removedFrom:attribute" (model, id, socketEvent)`](#removedfromattribute)
 
 * ### [`"destroyed" (model, socketEvent)`](#destroyed)
 
 * ### [`"updated" (model, socketEvent)`](#updated)
 
 * ### [`"updated:attribute" (model, value, socketEvent)`](#updatedattribute)
 
 * ### [`"messaged" (model, socketEvent)`](#messaged)
 
 * ### [`"socketSync" (model, response, options)`](#socketsync)
 
 * ### [`"socketError" (model, response, options)`](#socketerror)
 
 * ### [`"socketRequest" (model, promise, options)`](#socketrequest)
 
 * ### [`"subscribed" (model, modelName)`](#subscribedmodel)

***

# `Backbone.Sails.Model`

### @type Object
### @extends `Backbone.Model`
### @override `fetch, save, destroy`

`Backbone.Sails.Model` is simply a `Backbone.Model` that fires ordinary `Backbone` events as well as [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events originating from a Sails backend. The `save` and `fetch` methods have been overridden to attempt to sync over socket's by default, delegating to [`sync`](http://backbonejs.org/#Model-sync) as configured (see the `socketSync` and `subscribe` configuration options).


## Methods

* ### `constructor/initialize([attrs], [options])`

 In addition to the [backbone configuration options](http://backbonejs.org/#Model-constructor), you can pass the `socketSync` and `subscribe` options to the model constructor.
 
 **@example**
 
 ```javascript
 var model = new Backbone.Sails.Model({}, { socketSync: true })
 ```

* ### `save([attrs[key, val]], [options])`
 `save` performs much the [same](http://backbonejs.org/#Model-save). You can pass the `socketSync` and `subscribe` options at the request level, as well as a `url` option. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

 **@params**
 * `[attrs]`
    A set of additional attributes to be persisted on the model resource.

 * `[key, val]`
    A single additional attribute, e.g. `model.save("name", "Ian")`.

 * `[options]`
    You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `save` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `fetch([options])`
 `fetch` performs much the [same](http://backbonejs.org/#Model-fetch). You can pass the `socketSync` and `subscribe` options at the request level, as well as a `url` option. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

 **@params**

 * `[options]`
 You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socketSync` and `subscribe` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `fetch` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `destroy([options])`
 `destroy` works just as [before](http://backbonejs.org/#Model-destroy). You can pass the `socketSync` and `subscribe` options at the request level, as well as a `url` option. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

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

* ### `addTo(key, model [,options])`

 `addTo` is a convenience method to [`add to`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) a collection associated to the model resource. It will make a POST request to `model/id/key` and attempt to create a new model resource as part of the associated collection. In that sense, you can think of it as an extension of `save`, however, you can only create new model resources with this function - not edit them (PUT is not supported through associated collections).
 
 Make sure you allow your users to [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this. Also, make sure the instance you are posting [`isNew`](http://backbonejs.org/#Model-isNew).
 
 `addTo` will *not*, by default, attempt to mutate `model.attributes`. You can pass the option `update` which will push to `model.attributes[key]` (or create a new array), triggering the [`change`](http://backbonejs.org/#Events-catalog) events upon resolution of request.
 
 _The blueprint [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) now returns the model resource added, not the model resource added to._
 
 **@params**
 
 * `key` A string indicating the association (attribute) to add to.
 
 * `model` The model to be added to the associated collection. This can be a pojo of key-val's or a [`Backbone.Model`](http://backbonejs.org/#Model).
 
 * `options` The options object to be passed along with the request.
   
   [`update`] Set to `true` to attempt to push to `model.attributes[key]` upon resolution.
   
 **@returns `$.Deferred()`**
   
 `addTo` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
 
 **@example**
 
 ```javascript
 // POST to /user/id/messages over the socket
 user.addTo("messages", { content: "Hi there!" }, { socketSync: true }).done(function(resp){
   // create the recent message model persisted
   message = new Message(resp);
   // the message resource should now be registered
   // we have to subscribe this instance clientside to forward server side events
   message.subscribe();
 })
 ```
 
 ```javascript
 // will push to user.attributes.messages after resolution
 // triggering `change` and `change:message`
 user.addTo("messages", message, { update: true }) // message.isNew() == true
 ```
 
* ### `removeFrom(key, model [,options])`
 
 `removeFrom` is a convenience method to [`remove from`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) a collection associated to the model resource. It will make a DELETE request to `model/id/key`. You can think of it as a special version of `destroy`.
  
  Make sure you allow your users to [`remove`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this. If the `model` you are deleting is not [`isNew()`](http://backbonejs.org/#Model-isNew), the promise returned will reject immediately.
  
 `removeFrom` will *not*, by default, attempt to mutate `model.attributes`. You can pass the option `update` which will attempt to remove from the array `model.attributes[key]`. If successful, will trigger the [`change`](http://backbonejs.org/#Events-catalog) events upon resolution of request.
  
 **@params**
  * `key` A string indicating the association (attribute) to add to.
  
  * `model` The model to be added to the associated collection. This can be a pojo of attribute-value's or a [`Backbone.Model`](http://backbonejs.org/#Model).
  
  * `options` The options object to be passed along with the request.
  
    [`update`] Set to true to attempt to update `this.attributes` upon resolution.
    
    [`idAttribute="id"`] The `id` attribute for the associated collection.
  
 **@returns `$.Deferred()`**
 
 `removeFrom` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
  
  **@example**
  
  ```javascript
  // DELETE to /user/id/messages over the socket
  result = user.removeFrom("messages", { id: "123abc" }, { socketSync: true })
  ```
  
* ### `subscribe()`
  `subscribe` will set up this model to listen for socket based events from the relevant event aggregator. It is only necessary to call this when you have created a new model instance for a model resource that is known to be subscribed to (on the server) for the socket connected.
  
 **@returns `$.Deferred`**
 
 **@example**
   
 ```javascript
 // POST to /user/id/messages over the socket
 user.addTo("messages", { content: "Hi there!" }, { socketSync: true }).done(function(resp){
   // upon syncing with socket's, an event aggregator will be created clientside
   // for the model resource 'message'
   
   // server side blueprint 'add' has been called
   // subscribing this socket to the message resource
   // let's create a message model from the resp
   
   message = new Message(resp);
   
   // at the moment this model is not subscribed
   // it is not listening to the event aggregator created earlier
   // subscribing it will set up the relevant listeners
   
   message.subscribe().done(function(){
    // message model will now fire its socket based events
   });
 })
 ```

## Events
Events is where the magic happens. Many server-originated [resourceful pub/sub event's](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) are triggered on a *subscribed* model, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your model server-side**. The core ethos of this plugin was to get these event's on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

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

* ### `"subscribed"`

 Triggered on your model when it is subscribed to it's model resource event aggregator. 

 **@params**
 * `model` The model that has been subscribed.
 * `modelName` The name or _identifier_ of the model resource that has been subscribed. e.g. `user`