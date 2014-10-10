# Backbone.Sails.Model v0.1

***

* ## [Methods](#methods-1)

 * ### [`.constructor/initialize([attrs], [options])`](#constructorinitializeattrs-options-1)

 * ### [`.save([attrs[key, val]], [options])`](#saveattrskey-val-options-1)
 
 * ### [`.fetch([options])`](#fetchoptions-1)
 
 * ### [`.destroy([options])`](#destroyoptions-1)
 
 * ### [`.configure(criteria[key, val])`](#configurekey-valcriteria-1)
 
 * ### [`.query(criteria[key, val])`](#querykey-valcriteria-1)
 
 * ### [`.addTo(key, model [,options])`](#addtokey-model-options-1)
 
 * ### [`.removeFrom(key, model [,options])`](#removefromkey-model-options-1)
 
 * ### [`.message([customEvent,] data)`](#messagecustomevent-data-1)
 
* ## [Events](#events-1)

 * ### [`"addedTo" (model, socketEvent)`](#addedto)

 * ### [`"addedTo:attribute" (model, id, socketEvent)`](#addedtoattribute)
 
 * ### [`"removedFrom" (model, socketEvent)`](#removedfrom)
 
 * ### [`"removedFrom:attribute" (model, id, socketEvent)`](#removedfromattribute)
 
 * ### [`"destroyed" (model, socketEvent)`](#destroyed)
 
 * ### [`"updated" (model, socketEvent)`](#updated)
 
 * ### [`"updated:attribute" (model, value, socketEvent)`](#updatedattribute)
 
 * ### [`"messaged" (model, data, socketEvent)`](#messaged)
 
 * ### [`"customEvent (model, data, socketEvent)"`](#customevent)

***

# `Backbone.Sails.Model`

### @type Object
### @extends `Backbone.Model`
### @override `save` `fetch` `destroy`

`Backbone.Sails.Model` is simply a `Backbone.Model` that fires ordinary `Backbone` events as well as [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events originating from a Sails backend. It has two additional methods `addTo` and `removeFrom` which make integrating with associated collections a little more streamline. 

 `Backbone.Sails.Model` requires a `modelName` property instead of a `urlRoot` or `url` property declared in the constructor:
 
 ```javascript
 Model = Backbone.Sails.Model.extend({
   modelName: 'user'
 })
 ```
 
 You can also configure a `Backbone.Sails.Model` at the *constructor* level by passing a `config` object:
 
 ```javascript
 Model = Backbone.Sails.Model.extend({
   config: {
     populate: ['user', 'users']
     sync: 'socket'
   }
 })
 ```

## Methods

* ### `constructor/initialize([attrs], [options])`

 Constructing `Backbone.Sails.Model`'s works exactly the same. You can pass an optional set of attributes to `set` on the model, as well as an optional `options` object.
 
 The `options` object, in addition to the [backbone configuration options](http://backbonejs.org/#Model-constructor), is used to configure the model at the *instance* level:
 
 **@example**
 
 ```javascript
 // This model will sync over sockets
 var model = new Backbone.Sails.Model({ name: "Ian" }, { sync: "socket" })
 ```

* ### `save([attrs[key, val]], [options])`
 `save` performs much the [same](http://backbonejs.org/#Model-save). It will return a promise. The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
 
 The `options` object, in addition to the [backbone configuration options](http://backbonejs.org/#Model-save), is used to set configuration options at the *request* level:
 
 ```javascript
 model.save({}, { populate: "user", method: "POST" }).done(function(body, status, result){
   // handle success
 })
 ```

 **@params**
 * `[attrs]`
    A set of additional attributes to be persisted on the model resource. e.g. `model.save({ name: "Ian" })`

 * `[key, val]`
    A single additional attribute, e.g. `model.save("name", "Ian")`.

 * `[options]`
    You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `socket` and `populate` configuration options on a per request basis.

* ### `fetch([options])`
 `fetch` performs much the [same](http://backbonejs.org/#Model-fetch). You can pass the `sync` and `populate` options at the request level. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

 **@params**

 * `[options]`
 You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.save](http://backbonejs.org/#Model-save)). In addition, you can override the `sync` and `populate` configuration options on a per request basis.

 **@returns `$.Deferred`**
 
 `fetch` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `destroy([options])`
 `destroy` works just as [before](http://backbonejs.org/#Model-destroy). You can pass the `sync` option at the request level. It will return either a pure `$.Deferred()` if synced over sockets, or a [`jqXHR`](http://api.jquery.com/jQuery.ajax/) if delegated to [`sync`](http://backbonejs.org/#Model-sync).

 **@params**

 * `[options]`
 You can pass the usual `success` and `error` callbacks in here, as well as plenty of options for `jqXHR` to get it's hands on (see [$.ajax](http://api.jquery.com/jQuery.ajax/) and [Model.destroy](http://backbonejs.org/#Model-destroy)). You can override the `sync` configuration option on a per request basis.

 **@returns `$.Deferred`**
 
 `destroy` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.

* ### `query([[key, val]criteria])`
  _Alias for `configure`_

* ### `configure([[key, val]criteria])`
 `configure` is a utility method to set configuration variables on this model instance. For models, it is used to configure the `populate` and `sync` options. You can pass an object of options, or a key-val pair.

 **@example**

 ```javascript
 model.configure({
  populate: "user"
 })
 model.query({ # query is alias for configure
  populate: ["user", "message"]
 })
 model.configure("populate", "user message")
 model.configure({
   populate: false # removes any inherited populate option
   sync: "socket ajax"
 })
 model.query("sync", ["socket", "ajax"])
 ```

* ### `addTo(key, model [,options])`

 `addTo` is a convenience method to [`add to`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) a collection associated to the model resource. It will make a POST request to `model/id/key` and attempt to add a record to the associated collection, returning a promise.
 
 If the model being added is not new, _this method will not update the state of that record on the server_. Use `save()` for that. If the model is new, _then this method will persist the state of the model on the server_.
 
 If you pass a `Backbone.Model` as `model`, _the model will be updated with the server response_. The server will always respond with it's current state of the record, without any populated attributes. If you want to add a record, without changing anything clientside, just pass the attributes: `user.addTo("messages", message.attributes)`.
 
 Make sure you allow your users to [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this.
 
 _The blueprint [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) has been changed to return the model resource added, not the model resource added to._
 
 **@params**
 
 * `key` A string indicating the association (attribute) to add to.
 
 * `model` The model to be added to the associated collection. This can be a pojo of key-val's or a [`Backbone.Model`](http://backbonejs.org/#Model).
 
 * `options` The options object to be passed along with the request. Note, you cannot populate `addTo` or `removeFrom` requests. If you want to populate the model added, do this in another fetch request.
   
 **@returns `$.Deferred()`**
   
 `addTo` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
 
 **@example**
 
 ```javascript
 // POST to /user/id/messages over the socket
 user.addTo("messages", { content: "Hi there!" }, { sync: "socket" }).done(function(resp){
   // create the recent message model persisted
   message = new Message(resp);
   // we could populate the replyTo attribute now
   message.fetch({ populate: "replyTo" }).done(function(){
     inReplyTo = new User(message.get("replyTo"))
   })
 })
 ```
 
* ### `removeFrom(key, model [,options])`
 
 `removeFrom` is a convenience method to [`remove from`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) a collection associated to the model resource. It will make a DELETE request to `model/id/key` returning a promise.
 
 This does not `destroy` the record being removed, just remove's it from the association collection.
  
 If you pass a `Backbone.Model` as `model`, _the model will be updated with the server response_. The server will always respond with it's current state of the record, without any populated attributes. If you want to add a record, without changing anything clientside, just pass the attributes: `user.removeFrom("messages", message.attributes)`.
  
  Make sure you allow your users to [`remove`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) by configuring your [policies](http://sailsjs.org/#/documentation/concepts/Policies) before attempting to call this. Make sure the `model` you are deleting is not [`isNew()`](http://backbonejs.org/#Model-isNew), else an error will be thrown.
  
 **@params**
  * `key` A string indicating the association (attribute) to add to.
  
  * `model` The model to be added to the associated collection. This can be a pojo of attribute-value's or a [`Backbone.Model`](http://backbonejs.org/#Model).
  
  * `options` The options object to be passed along with the request. You can specify `sync` here.
  
 **@returns `$.Deferred()`**
 
 `removeFrom` will return a `$.Deferred`. If synced over socket's,  the deferred will resolve with parameters `(jwres.body, jwres.statusCode, jwres)` where `jwres` refers to [JSON WebSocket Response](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) otherwise the deferred will reject with parameters `(jwres, jwres.statusCode, jwres.body)`. If synced over `jqXHR`, see [$.ajax](http://api.jquery.com/jQuery.ajax/) for details of resolution.
  
  **@example**
  
  ```javascript
  // DELETE to /user/id/messages over the socket
  result = user.removeFrom("messages", { id: "123abc" }, { sync: 'socket' })
  ```
  
* ### `.message([customEvent,] data)`

  `message` is used to send a message to all model instances of this record that are subscribed clientside. Fundamentally, this allows you to communicate with other browser sessions, *without modifying the record referenced* - a powerful paradigm.
  
  `message` relies on a blueprint route that isn't part of the core Sails blueprints. As such, you'll have to (as of sails v0.10) include the message action in the controller yourself:
  
  SomeController.js
  ```javascript
  module.exports = {
    message: require("./blueprints/message")
  }
  ```
  
  `message` always sends a simple `data` object. You can also call `message` with a `customEvent` string, which allows you to fully describe the purpose of the message:
  
  ```javascript
  model.message("execute:update", { response: "ok" })
  
  // somewhere else on some other subscribed model instance
  model.on("execute:update", function(m, data){
    if(data.response == "ok") {
      // do stuff
    }
  })
  ```
  
## Events
Events are where the magic happens. Many server-originated [resourceful pub/sub event's](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) are triggered on a *subscribed* model, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your model server-side**. The core ethos of this plugin was to get these event's on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

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

 Triggered on your model when the record it refers to is [messaged](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html). This *does not* fire if you pass a `customEvent` string into the `message` method.

 **@params**
 
 * `model` The model that has been messaged.
 * `data` The data object passed along with the message.
 * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).#
 
 * ### `"customEvent"`
 
  Triggered on your model when the resource it refers to is [messaged](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html). This event fires when you pass a `customEvent` string into the `message` method.
 
  **@params**
  
  * `model` The model that has been messaged.
  * `data` The data object passed along with the message.
  * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).