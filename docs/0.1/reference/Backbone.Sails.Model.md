

<!--- MAIN TITLE & VERSIONING --->


# [Backbone.Sails.Model v0.1](#backbonesailsmodel)

***


<!--- METHOD LINKS --->


* ## [Methods](#methods-1)

  * ### [`constructor([attributes] [,options])`](#constructorattributes-options-1)
  
  * ### [`.save([{attributes} | {attribute, value}] [,options])`](#saveattributes--attribute-value-options-1)
  
  * ### [`.fetch([attribute] [,options])`](#fetchattribute-options-1)
  
  * ### [`.destroy([options])`](#destroyoptions-1)
  
  * ### [`.addTo(attribute, model [,options])`](#addtoattribute-model-options-1)
  
  * ### [`.removeFrom(attribute, model [,options])`](#removefromattribute-model-options-1)
  
  * ### [`.get(attribute [,wrap])`](#getattribute-wrap-1)
  
  * ### [`.set(attribute, value [,options])`](#setattribute-value-options-1)
  
  * ### [`.populate(criteria)`](#populatecriteria-1)
  
  * ### [`.query({criteria} | {option, value})`](#querycriteria--option-value-1)
  
  * ### [`.configure({criteria} | {option, value})`](#configurecriteria--option-value-1)
  
  * ### [`.message([customEvent,] data)`](#messagecustomevent-data-1)
  
  * ### [`.subscribe()`](#subscribe-1)
 
 
<!--- EVENT LINKS --->
 
 
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


<!--- SECONDARY TITLE --->


# `Backbone.Sails.Model`


<!--- OBJECT DECLARATION --->


### @type Object
### @extends `Backbone.Model`
### @override `save` `fetch` `destroy`

`Backbone.Sails.Model` is simply a `Backbone.Model` that fires ordinary `Backbone` events as well as [resourceful pub/sub (or comet)](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events originating from a Sails backend. It has a number of additional methods which make integrating with associated collections a little more streamline. `Backbone.Sails.Model` will, by default, sync over websockets, delegating to ajax if unavailable.

`Backbone.Sails.Model` requires a `modelName` property instead of a `urlRoot` or `url` property declared in the constructor (it will also pick this up from it's parent collection, if not declared):

```javascript
var Model = Backbone.Sails.Model.extend({
  modelName: 'user'
})
```

You can also configure a `Backbone.Sails.Model` at the *constructor* level by passing a `config` object:

```javascript
var Model = Backbone.Sails.Model.extend({
  config: {
    populate: ['user', 'users']
    sync: 'socket'
  }
})
```

Any associations should also be declared within the constructor function, as part of the `assoc` object. The `assoc` object is used to reference the constructors by which the implementation will wrap raw data objects:

```javascript
var Person = Backbone.Sails.Model.extend({
  assoc: {
    address: Address, // an associated model, `Address` is address constructor
    messages: MessageColl, // an associated collection, `MessageColl` is a collection constructor
  }
})
```

Passing the constructor's, for simple models/collections, can get a little tedious. So, there is a convenience where you can just pass a `String` of the `modelName`, to indicate an associated *model*. Or, you can pass an array of a single `String` of the `modelName`, to indicate an associated *collection*:

```javascript
var Person = Backbone.Sails.Model.extend({
  assoc: {
    address: 'address', // an associated model, `address` is the model identifier
    messages: ['message'], // an associated collection, `message` is the model identifier
  }
})
```

There are often times when you have a circular dependence between models (a `Person` has an `Address`, an `Address` has `Person`'s). In which case, you will have to pass a function returning a reference to a constructor for that associated model/collection:

```javascript
var Address;
var Person = Backbone.Sails.Model.extend({
  assoc: {
    address: function(){ return Address; }
  }
})
var People = Backbone.Sails.Collection.extend({ model: Person })
Address = Backbone.Sails.Model.extend({
  assoc: {
    occupants: People
  }
})
```

This also works for self referencing model's (a `Person` has a `Person` as a spouse, for example).


<!--- METHOD REFERENCE --->


## Methods


<!--- CONSTRUCTOR() --->


* ### `constructor([attributes] [,options])`

  Constructing `Backbone.Sails.Model`'s is much the same. You can pass an optional set of attributes to `set` on the model, as well as an optional `options` object.
  
  The `options` object, in addition to the [backbone configuration options](http://backbonejs.org/#Model-constructor), is used to configure the model at the *instance* level:
  
  **@example**
  
  ```javascript
  // This model will sync over sockets, without delegating to ajax
  var model = new Backbone.Sails.Model({ name: "Ian" }, { sync: "socket" });
  ```
  
  **@params**
  * `[attributes]` A set of initial attributes to be `set` on the model.
  
  * `[options]` You can pass *instance* level configuration in here.
    
    
<!--- .SAVE() --->


* ### `save([{attributes} | {attribute, value}] [,options])`
  
  `save` performs much the [same](http://backbonejs.org/#Model-save). It will return a jQuery promise (by default) indicating the success or failure of the http request.
  
  The `options` object, in addition to the [backbone configuration options](http://backbonejs.org/#Model-save), is used to set configuration options at the *request* level:
  
  ```javascript
  model.save({}, { populate: "user", method: "POST" }).done(function(body, status, result){
    // handle success
  })
  ```
  
  **@params**
  * `[attributes]` A set of additional attributes to be persisted on the model resource. e.g. `model.save({ name: "Ian" })`
  
  * `[attribute, value]` A single additional attribute to be persisted, e.g. `model.save("name", "Ian")`.
  
  * `[options]` You can pass *request* level configuration options in here, as well as relevant Backbone & jQuery options.
    
  **@returns** `Promise`
  
  `save` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
   
  **@http**
  * POST `/modelName` : [`create`](http://sailsjs.org/#/documentation/reference/blueprint-api/Create.html) *blueprint*
   
    `save` will POST to `/modelName` if the model `isNew()`
   
  * PUT `/modelName/id` : [`update`](http://sailsjs.org/#/documentation/reference/blueprint-api/Update.html) *blueprint*
   
    `save` will PUT to `/modelName/id` if the model `!isNew()`


<!--- .FETCH() --->


* ### `fetch([attribute] [,options])`

  `fetch` performs much the [same](http://backbonejs.org/#Model-fetch). It will return a jQuery promise (by default) indicating the success or failure of the http request.
  
  `fetch` is also overloaded to call the `populate` blueprint by making a request to `/modelName/id/attr`. To do this, you can pass the `attr` you would like to populate as a string for the first parameter. The `populate` blueprint will return the populated record requested. This can be a model or a collection. If it is a collection, you can specify filter criteria at the *request* level within the options object. When you call `fetch` with an `attr` string as the first parameter, is *does not update the state of the record referenced*. Instead, the promise returned will resolve with the populated model as a first parameter. That is, `fetch` will resolve with `(instance, response, statusCode, xhr)` instead of `(response, statusCode, xhr)`:
  
  ```javascript
  jill = new Person({ id: "123" });
  
  jill.fetch("children").done(function(children){
  
    // children is a collection of children associated to jill
  
  })
  ```
  
  **@params**
  
  * `[attribute]` This is a string that, if present, will overload `fetch` to populate the `attr` requested. This means `fetch` will return a promise which resolves with the `attr` requested as the first parameter. It will be wrapped with whatever constructor found in the `assoc` declarations as part of the model definition.
  
  * `[options]` You can pass *request* level configuration options in here. If you are populating an associated collection, you can also pass filter/limit/sort criteria, to tailor the response (though this criteria will not be copied onto the associated collection).
  
  **@returns** `Promise`
  
  `fetch` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets. If `fetch` is being used to call the populate blueprint, the instance populated will be the first parameter of the resolution.
  
  **@http**
  
  * GET `/modelName/id` : `findOne` *blueprint*
  
    `fetch` will call the `findOne` blueprint in order to update the state of the model.
   
  * GET `/modelName/id/attr` : `populate` blueprint
  
    If `attr` is a string passed as the first parameter, `fetch` will call the `populate` blueprint, resolving with the instance populated. *This will not update the state of the model on which `fetch` is called*.


<!--- .DESTROY() --->


* ### `destroy([options])`

  `destroy` works just as [before](http://backbonejs.org/#Model-destroy). It will send over sockets or ajax as configured.
  
  **@params**
  
  * `[options]` You can pass *request* level configuration options in here, as well as relevant Backbone & jQuery options.
  
  **@returns `Promise`**
  
  `destroy` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * DELETE `/modelName/id` : `destroy` *blueprint*
 
    `destroy` will send a DELETE request if the model is `!isNew()`.


<!--- .ADDTO() --->


* ### `addTo(attribute, model [,options])`

  `addTo` is a convenience method to [`addTo`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html) a collection associated to the model resource. It will make a POST request to `model/id/attribute` and attempt to add a record to the associated collection, returning a promise.
  
  `addTo` will always update the state of the record on which it is being added to. In that sense, it works a lot like `save`.
  
  `addTo` will only update the model being added if `model` is a `Backbone.Sails.Model` (as opposed to a POJO) and *if the `model` is new*.
  
  `addTo` will not always return the record added as a direct part of the response from the server. The response from the server will be configured in accordance with the filter/sort/limit/populate criteria configured on the instance being added to. If a new model is created through an `addTo` request, the new model data will come back as part of the `created` header.
  
  `addTo` will throw an error if you attempt to `addTo` a model which is `isNew()`.
  
  `addTo` will throw an error if you attempt to `addTo` an attribute which isn't an associated collection.
  
  **@params**
  
  * `attribute` A string indicating the association (attribute) to add to.
  
  * `model` The model to be added to the associated collection. This can be a pojo of key-val's or a [`Backbone.Model`](http://backbonejs.org/#Model) or simply an id string.
  
  * `[options]` The configuration options to be set at the *request* level, as well as the relevant jQuery & Backbone configuration options.
   
  **@returns `Promise`**
   
  `addTo` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * POST `/modelName/id/attribute` : `add` *blueprint*
  
    `addTo` will send the model (or just the model id) to be added as the http body to the associated collection. 
  
  **@example**
  
  ```javascript
  // You can add with a POJO
  user.addTo("messages", { content: "Hi there!" }, { sync: "socket" }).done(function(resp){
   
    // `user` has been updated with server response
    // Has now created a new message and associated it to `user`
    // However, since we passed a POJO, we cannot easily access
    // the message created. We can add a model to do that.
   
  })
  
  // You can add a new model
  message = new Message({ content: "Hi there!" });
  user.addTo("messages", message).done(function(resp){
    
    // Has now created a new message and associated it to `user`
    // `user` has been updated with the server response as well
    // as the `message`
    
  })
  
  // You can also add model's which aren't new
  // They will, however, not be `set` (or updated)
  message = new Message({ id: "abc" })
  message.isNew(); // false
  user.addTo("messages", message).done(function(resp){
     
    // Here, message will be added, but not updated with any server response
    // user will be updated however
     
  })
  ```

<!--- .REMOVEFROM() --->


* ### `removeFrom(attribute, model [,options])`
 
  `removeFrom` is a convenience method to [`removeFrom`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html) a collection associated to the model resource. It will make a DELETE request to `model/id/key` returning a promise.
  
  This **does not** `destroy` the record being removed, just remove's it from the association collection.
  
  `removeFrom` will throw an error if you attempt to `removeFrom` a model which is `isNew()`.
  
  `removeFrom` will throw an error if you attempt to `removeFrom` an attribute which isn't an associated collection.
  
  **@params**
  * `attribute` A string indicating the associated collection to remove from.
  
  * `model` The model to be removed from the associated collection. This can be a pojo of attribute-value's or a [`Backbone.Model`](http://backbonejs.org/#Model) or simply an id string.
  
  * `[options]` The configuration options to be set at the *request* level, as well as the relevant jQuery & Backbone configuration options.
  
  **@returns `Promise`**
  
  `removeFrom` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * DELETE `/modelName/attribute/id` : `removeFrom` *blueprint*
  
    `removeFrom` will send a DELETE request to the url of the associated collection. This does not destroy any records, simply removes (or destroys) the *association*.
  
  **@example**
  
  ```javascript
  // DELETE to /user/id/messages over the socket
  // We use an id here
  result = user.removeFrom("messages", "123abc", { sync: 'socket' })
  ```


<!--- .GET() --->


* ### `get(attribute [,wrap])`

  Get works as before, except for the `wrap` parameter. If `wrap` is true, and you are requesting to `get` an associated attribute, `get` will wrap the data with the associated constructor declared within the `assoc` object, as part of the model definition.
  
  ```javascript
  var Person = Backbone.Sails.Model.extend({
    assoc: {
      address: Address
    }
  });
  
  var bob = new Person({ id: "abc" });
  bob.populate("address").fetch().done(function(){
   
    // here we can either grab the raw data for the address
    
    var addressRaw = bob.get("address"); // a POJO
    
    // or we can wrap it with the `Address` constructor
    
    var address = bob.get("address", true); // an `Address` model
    
    address.set("number", 4).save()
   
  })
  ```
  
  **@params**
  
  * `attribute` A string indicating the attribute to `get`.
   
  * `[wrap]` A boolean indicating whether to `wrap` the data with a constructor declared within the `assoc` object.
  
  **@returns** `Object`
  
  `get` will return either the raw data from within the backbone `attributes` object, or it will `wrap` the data with a constructor and return either a `Model` or `Collection`.


<!--- .SET() --->


* ### `set(attribute, value [,options])`

  Set works as before. It is overloaded to take models and collections as well:
  
  ```javascript
  johnnyRaw = { name: "johnny" };
  johnny = new Person(johnnyRaw);
  
  // these both do the same thing
  fred.set('friend', johnnyRaw);
  fred.set('friend', johnny);
  ```
  
  **@params**
  
  * `attribute` The attribute to `set`.
  
  * `value` The value of the attribute to `set`. This can either be a primitive (string, number, POJO, array, etc...) or a model or a collection.
  
  * `[options]` Backbone configuration options can be passed here.
  
  **@chainable**


<!--- .POPULATE() --->


* ### `populate(criteria)`

  _A convenience for `configure("populate", criteria)`._
  

<!--- .QUERY() --->


* ### `query({criteria} | {option, value})`

  _Alias for `configure`_.


<!--- .CONFIGURE() --->


* ### `configure({criteria} | {option, value})`

  `configure` is a method to set configuration options at the *instance* level. You can pass an object of options, or a key-val pair.
  
  **@example**
  
  ```javascript
  model.configure({
    populate: "user"
  })
  
  model.query({
    populate: ["user", "message"]
  })
  
  model.configure("populate", "user message")
  
  model.configure({
    populate: false // removes any inherited option's
    sync: "socket ajax"
  })
  
  model.query("sync", ["socket", "ajax"])
  ```
  
  **@params**
  
  * `{criteria}` This should be object of configuration options to set at the *instance* level.
  
  * `{option, value}` A single configuration option can be set by passing an `option` string, and the value.
   
  **@chainable**


<!--- .MESSAGE() --->


* ### `message([customEvent,] data)`

  `message` is used to send a message to all model instances of this record that are subscribed clientside. Fundamentally, this allows you to communicate with other browser sessions, *without modifying the record referenced* - a powerful paradigm.
  
  `message` relies on a blueprint route that isn't part of the core Sails blueprints. As such, you'll have to (as of sails v0.10) include the message action in the controller yourself:
  
  *SomeController.js*
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
  
  **@returns `Promise`**
  
  `message` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * POST `/modelName/message/id` : `messageOne` *blueprint*


<!--- .SUBSCRIBE() --->


* ### `subscribe()`

  This method is used internally for the most part. When called, the implementation will attempt to set up listeners for this model to it's respective *event aggregator*. The implementation does this for you whenever an instance is created, or when it's id changes - so it is highly unlikely you'll ever touch this.
 
 
<!--- EVENTS REFERENCE --->

  
## Events
Events are where the magic happens. Many server-originated [resourceful pub/sub event's](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) are triggered on a *subscribed* model, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your model server-side**. The core ethos of this plugin was to get these event's on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

*You can prefix these event identifiers making use of the `eventPrefix` configuration option.*


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