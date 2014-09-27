# Backbone.Sails.Model v0.1

***

* ## [Methods](#methods)

 * ### [`save([attrs[key, val]], [options])`](#saveattrskey-val-options)
 
 * ### [`fetch(attrs[key, val], [options])`](#fetchattrskey-val-options)
 
 * ### [`destroy([options])`](#destroyoptions)
 
 * ### [`query([criteria])`](#querycriteria)
 
 * ### [`addTo(key, model [,options])`](#addtokey-model-options)
 
 * ### [`removeFrom(key, model [,options])`](#removefromkey-model-options)
 
 * ### [`toOne(key, model)`](#toonekey-model)
 
 * ### [`subscribe()`](#subscribe)
 
* ## [Events](#events)

 * ### [`addedTo(model, socketEvent)`](#addedto)

 * ### [`addedTo:attribute(model, id, socketEvent)`](#addedtoattribute)
 
 * ### [`removedFrom(model, socketEvent)`](#removedfrom)
 
 * ### [`removedFrom:attribute(model, id, socketEvent)`](#removedfromattribute)
 
 * ### [`destroyed(model, socketEvent)`](#destroyed)
 
 * ### [`updated(model, socketEvent)`](#updated)
 
 * ### [`updatedattribute(model, value, socketEvent)`](#updatedattribute)
 
 * ### [`messaged(model, socketEvent)`](#messaged)
 
 * ### [`socketsync(model, response, options)`](#socketsync)
 
 * ### [`socketError(model, response, options)`](#socketerror)
 
 * ### [`socketRequest(model, promise, options)`](#socketrequest)
 
 * ### [`subscribed:model(model, modelName)`](#subscribedmodel)

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

* ### `addTo(key, model [,options])`

 `addTo` is a convenience method to [`add to`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) a collection associated to the model resource referenced by this model. It will make a POST to `model/id/key` and attempt to create a new model resource as part of the associated collection.
 
 Make sure you allow your users to [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this. Also, make sure the instance you are posting [`isNew`](http://backbonejs.org/#Model-isNew), Otherwise, the promise returned will reject immediately. Why? Sails has no method for PUT'ing to associated collection's or model's - bare in mind the RESTful controllers, by default, only allow you to [POST](http://sailsjs.org/#/documentation/reference/blueprint-api/Create.html) and [DELETE](http://sailsjs.org/#/documentation/reference/blueprint-api/Destroy.html).
 
 This method will *not* mutate the client side `Backbone.Model` object on which `addTo` is being called. You are welcome to do that yourself, after the `addTo` has resolved (see the example usage). Though you might find creating an [associated collection]() better suits your needs. **Or**, you can set `update` to true in the `options` object to attempt to mutate `this.attributes` upon resolution.
 
 The blueprint [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) has been changed slightly to play nicely with this clientside API. *Instead of returning the model resource being added to, it now returns the model resource added.*
 
 **@params**
 
 * `key` A string indicating the association (attribute) to add to.
 
 * `model` The model to be added to the associated collection. This can be a pojo of attribute-value's or a [`Backbone.Model`](http://backbonejs.org/#Model).
 
 * `options` The options object to be passed along with the request.
   [`update`] Set to true to attempt to update `this.attributes` upon resolution, triggering the relevant `change` events.
   
 **@returns `$.Deferred()`**
   
 `addTo` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
 
 **@example**
 
 ```javascript
 // POST to /user/id/messages over the socket
 user.addTo("messages", { content: "Hi there!" }, { socketSync: true }).done(function(resp){
   user.attributes.messages.push(resp);
   user.trigger("change"); user.trigger("change:messages");
   
   // OR create the recent message model persisted
   message = new Message(resp);
   // the message resource should now be registered
   // we have to subscribe this instance clientside to forward server side events
   message.subscribe();
 })
 ```
 
 ```javascript
 // essentially achieves the same as the above
 // the message model will be subscribed after this request resolves over sockets
 user.addTo("messages", message, { update: true })
 ```
 
* ### `removeFrom(key, model [,options])`
 
 `removeFrom` is a convenience method to [`remove from`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) a collection associated to the model resource referenced by this model. It will make a DELETE to `model/id/key` and attempt to delete the model resource specified by the `model`.
  
  Make sure you allow your users to [`remove`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this. Make sure the `model` you are deleting is not [`isNew()`](http://backbonejs.org/#Model-isNew). Otherwise, the promise returned will reject immediately.
  
 This method will *not* mutate the client side `Backbone.Model` object on which `removeFrom` is being called. You are welcome to do that yourself, after the `removeFrom` has resolved (see example usage). You might find creating an [associated collection]() better suits your needs. **Or**, you can set `update` to true in the `options` object to attempt to mutate `this.attributes` upon resolution.
  
 **@params**
  * `key` A string indicating the association (attribute) to add to.
  
  * `model` The model to be added to the associated collection. This can be a pojo of attribute-value's or a [`Backbone.Model`](http://backbonejs.org/#Model).
  
  * `options` The options object to be passed along with the request.
    [`update`] Set to true to attempt to update `this.attributes` upon resolution, triggering the relevant `change` events.
  
 **@returns `$.Deferred()`**
 
 `removeFrom` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
  
  **@example**
  
  ```javascript
  // POST to /user/id/messages over the socket
  result = user.removeFrom("messages", { id: "123abc" }, { socketSync: true })
  ```
  
* ### `toOne(key, model)`
  `toOne` is a convenience function for `this.set(key, model.id)`. It is chainable (returns `this`).
  
* ### `subscribe()`
  `subscribe` will set up this model to listen for socket based events from the relevant event aggregator. It is only necessary to call this when you have created a new model instance for a model resource that is known to be subscribed to (on the server) for the socket connected. If you are unsure what that means, simply call `this.fetch({ socketSync: true }).done(// socket stuff)` to guarantee that this model is registered to receive socket events.
  
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
      // doing it this way avoids another socket request
      
     });
   })
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