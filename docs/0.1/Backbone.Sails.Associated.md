# Backbone.Sails.Associated v0.1

***

# `Backbone.Sails.Associated(Backbone.Sails.Collection)`

### @type Function

This is a function which takes a `Backbone.Sails.Collection` *constructor* (not an instance) and returns a collection constructor which creates 'associated' collections of the same type. The constructor returned is very different from ordinary collection constructors. Instead of instantiating with `([models], [options])`, associated collections are created from a `model` instance as well as a `key` and an optional `options` object. See the following example...

```javascript
// user model
var User = Backbone.Sails.Model.extend({
  urlRoot: "/user"
})

// a 'normal' message collection
var Messages = Backbone.Sails.Collection.extend({
  url: "/message"
})

// wrap the Messages constructor
var AssociatedMessages = Backbone.Sails.Associated(Messages)

// create a user
var user = new User({ id: "123" });

// and create the messages associated to that user
// the constructor takes a model, a key and optional options
var userMessages = new AssociatedMessages(user, 'messages', { socketSync: true })

// we can now fetch the messages associated to that user
userMessages.fetch().done(function(){

  // we should now pick up events for that user
  // the 'addedTo' and 'removedFrom' events are fired
  // on this collection
  
  userMessages.on("addedTo", function(){ // handle new message })
  
  userMessages.on("removedFrom", function(){ // handle message removal })
  
  // ordinarily you cannot PUT to associated collections
  // however, with an associated collection, you can
  
  message = userMessages.get("345")
  message.set("content", "This has been edited")
  
  message.save() // will send a PUT

})

```

The returned collection will extend the collection passed. The `model` of the collection will also extend the `model` of the collection passed.

When creating an associated collection from a `model` instance, make sure that **model is subscribed on the server** before attempting to listen for `addedTo` and `removedFrom` events on the associated collection.

It is worth mentioning that, once constructed, the Associated Collection does not depend upon the existence of the model instance it was constructed with. This allow's you to listen to the associated collection, without necessarily listening to the model is was instantiated with.

If the `model.attributes[key]` is *populated*, the constructor will use those records to instantiate the collection.

There are two different ways to 'add to' an associated collection. You can either `push` a set of attributes:

```javascript
m = messages.push({ content: "Hi" })
// m.isNew() == true
m.save()
// new message record has now been added to associated collection
```

Or you can create new models, *using the `model` class from the associated collection*:

```javascript
Model = messages.model
m = new Model({ content: "Hi" })
messages.push(m)
m.save()
```

It isn't necessary to construct associated collections with a `Backbone.Sails.Model`, nor is it necessary to wrap a `Backbone.Sails.Collection`. However, the socket events may not fire as intended.

## Methods

* ### `constructor/initialize(model, key [, options])`

 Associated collections need a `model` instance, and a `key` to be created.
 
 **@params**
 
 * `model` The model instance to associate the collection with. If `model.attributes[key]` is *populated*, the associated collection will be initialized with those records.
 * `key` A string indicating the attribute which is an associated collection. e.g. `users`
 * `[options]` A object with collection-wide options. e.g. `socketSync`

## Events

The collection has two extra event's it will fire, `addedTo` and `removedFrom`, in addition to those bubbled up from the models currently in the collection.

* ### `"addedTo"`

 Triggered when the collection is [`addedTo`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).

 **@params**
 
 * `addedId` The id of the record added to the associated collection.
 * `socketEvent` The original event from the Sails backend, as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishAdd.html).
 
* ### `"removedFrom"`

 Triggered when the collection is [`removedFrom`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).

 **@params**
  
  * `removedId` The id of the record that was removed from the associated collection.
  * `socketEvent` The original event from the Sails backend, as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishRemove.html).
  
* ### `"subscribed:collection"`

 Triggered when the collection is successfully subscribed on the client side.

 **@params**
  
 * `collection` The associated collection.
 * `modelName` The model name, or the 'event identifier', e.g. 'user'.
 
 
 
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

