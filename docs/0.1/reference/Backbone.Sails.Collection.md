

<!--- MAIN TITLE & VERSIONING --->


# [Backbone.Sails.Collection v0.1](#backbonesailscollection)

***


<!--- METHOD LINKS --->


* ## [Methods](#methods-1)

  * ### [`constructor([models] [,options])`](#constructormodels-options-1)
  
  * ### [`.fetch([options])`](#fetchoptions-1)
  
  * ### [`.populate(criteria)`](#populatecriteria-1)
  
  * ### [`.query({criteria} | {option, value})`](#querycriteria--option-value-1)
  
  * ### [`.configure({criteria} | {option, value})`](#configurecriteria--option-value-1)
  
  * ### [`.message([customEvent,] data)`](#messagecustomevent-data-1)
  
  * ### [`.subscribe()`](#subscribe-1)


<!--- EVENT LINKS --->


* ## [Events](#events-1)

  ### [`"created" (modelData, socketEvent)`](#created)
  

<!--- BUBBLED EVENT LINKS --->


* ## [Events bubbled from `Backbone.Sails.Model`](#events-bubbled-from-backbonesailsmodel-1)

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


# `Backbone.Sails.Collection`


<!--- OBJECT DECLARATION --->


### @type Object
### @extends `Backbone.Collection`
### @override `fetch`

`Backbone.Sails.Collection` is simply a `Backbone.Collection` that fires ordinary `Backbone` events as well as [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events originating from a Sails backend. It will sync over sockets by default, delegating to ajax if web sockets aren't available.

When declaring a `Backbone.Sails.Collection`, it is generally recomended that you pass a `modelName` property, at the very least. If your feeling really lazy, you can just pass a `model` with a `modelName`, if you like.

If you pass a `model`, make sure it has the same `modelName` as the collection (if any) and that it is a `Backbone.Sails.Model`.

The default [`model`](http://backbonejs.org/#Collection-model) of a `Backbone.Sails.Collection` is (naturally) a `Backbone.Sails.Model` with the `modelName` of the collection. So, you don't *have to* declare a `model`, when declaring collections.

```javascript
var User = Backbone.Sails.Model.extend({
  modelName: 'user'
})

var UserCollection = Backbone.Sails.Collection.extend({
  modelName: 'user', // optional, since `model` is declared
  model: User
})
```


<!--- METHOD REFERENCE --->

## Methods


<!--- CONSTRUCTOR() --->


* ### `constructor([models] [,options])`

  Constructing collection's works exactly the same. In addition to the [backbone configuration options](http://backbonejs.org/#Collection-constructor), you can pass *instance level* configuration options within the `options` object. This allow's you to configure how to sync with the server, or set the default `populate` criteria, for example.
  
  **@example**
  
  ```javascript
  var coll = new Backbone.Sails.Collection([],
    {
      sync: 'socket ajax subscribe',
      populate: {
        friends: {
          where: { name: { contains: 'a' } }
        }
      }
    })
  ```


<!--- .FETCH() --->


* ### `fetch([options])`

  `fetch` performs much the [same](http://backbonejs.org/#Collection-fetch), however, you can specify filter criteria for the resources to be fetched using the `query` method, before making any GET requests.
  
  ```javascript
  coll.query({
    skip: 10,
    limit: 10,
    sort: {
      lName: 1, // lName ascending primary
      fName: 1  // fName ascending secondary
    },
    where: {
      lName: {
        startWith: 'J'
      }
    }
  }).fetch().done(function(){
    
    // coll is now updated
    
  })
  ```
  
  **@params**
  
  * `[options]` You can pass *request* level configuration options in here, as well as relevant Backbone & jQuery options.
  
  **@returns `Promise`**
  
  `fetch` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * GET `/modelName` : `find` blueprint


<!--- .POPULATE() --->


* ### `populate(criteria)`

  *Convenience for `configure('populate', criteria)`*


<!--- .QUERY() --->


* ### `query({criteria} | {option, value})`

  *Alias for `configure({criteria} | {option, value})`*
  
  
<!--- .CONFIGURE() --->
  
  
* ### `configure({criteria} | {option, value})`
  
  `configure` is a method to set configuration options at the *instance* level. You can pass an object of options, or a key-val pair.
    
  **@example**
  
  ```javascript
  coll.configure({
    populate: "user",
    sync: 'socket',
    sort: 'fName ASC',
    limit: 10
    // , where: ...
    // , skip: ..
  })
  ```
  
  **@params**
  
  * `{criteria}` This should be an object of configuration options to set at the *instance* level.
  
  * `{option, value}` A single configuration option can be set by passing an `option` string, and the value.
   
  **@chainable**


<!--- .MESSAGE() --->

* ### `message([customEvent,] data)`

  *From the `Model` reference...*
  
  > `message` is used to send a message to all model instances of this record that are subscribed clientside. Fundamentally, this allows you to communicate with other browser sessions, *without modifying the record referenced* - a powerful paradigm.

  When `message` is called on a collection, the idea is that is will `message` all the model's of the collection. However, a `Backbone.Sails.Collection`, in essence, has two states. The models currently referenced within the clientside collection(the client state), and those that will be returned upon the next `fetch()` (the server state). The server state is precisely specified by the filter configuration options (`sort`, `skip`, `limit`, `where`).
  
  When `message` is called on a collection, it will, by default, message all the model's within the client state of the collection. You can override this behaviour making use if the `state` configuration option. This option can be set at all level's of configuration:
  
  ```javascript
  
  user = new UserCollection({
    config: {
      limit: 1000000
    }
  })
  
  // we'll tell the first million user's when
  // a user is destroyed using a custom event
  // we don't have to fetch them to do this - pretty cool eh?
  users.message('destroyed', { id: "123" }, {
    state: 'server'
  })
  
  ```
  
  **@returns `Promise`**
  
  `message` will return a `Promise` (by default, a jQuery promise). The promise will resolve with the parameters [`(body, status, jqXHR)`](http://api.jquery.com/jQuery.ajax/#jqXHR) if synced over ajax, or [`(body, status, jwres)`](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js/socket.get.html) if synced over sockets.
  
  **@http**
  
  * POST `/modelName/message` : `message` *blueprint*


<!--- .SUBSCRIBE() --->


* ### `subscribe()`

  This method is used internally for the most part. When called, the implementation will attempt to set up listeners for this model to it's respective *event aggregator*. The implementation does this for you whenever an instance is created, or when it's id changes - so it is highly unlikely you'll ever touch this.


<!--- EVENTS --->


## Events
Events are where the magic happens. Many server-originated [resourceful pub/sub event's](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) are triggered on a *subscribed* collection, in addition to the usual `Backbone` events. These additional event's open up the possibility to **respond to changes on your collection server-side**. The core ethos of this plugin was to get these event's on your models and collections, without spa-ghe-ty-ing your way around `io.socket.on` and the likes. Take a good long look... 

_You can prefix these event identifiers making use of the `eventPrefix` configuration option._

* ### `"created"`

  Triggered on your collection when a model resource is [`created`](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html).
  
  **@params**
  * `data` A POJO representing the created resource. That is, a series of key-val attributes. *Not* a `Backbone.Model`.
  * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/publishCreate.html).


<!--- BUBBLED EVENTS --->


## Events bubbled from `Backbone.Sails.Model`
These events are bubbled from model's within the collection, a standard practice for Backbone collections.

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
  * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).
 
* ### `"customEvent"`
 
  Triggered on your model when the resource it refers to is [messaged](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html). This event fires when you pass a `customEvent` string into the `message` method.
  
  **@params**
  
  * `model` The model that has been messaged.
  * `data` The data object passed along with the message.
  * `socketEvent` The original socket event as documented [here](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub/message.html).