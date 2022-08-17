Backbone.Sails
==============

# *This project has now been discontinued*. Please contact me if you are interested in picking up the development of this project.

Backbone.Sails is a plugin that aims to leverage to best of a [Sails](http://sailsjs.org/#/) backend within a [Backbone](http://backbonejs.org/#) frontend.

#### Intro

Sails is a [nodejs](http://nodejs.org/) framework built on top of [express](http://expressjs.com/). It features fantastic support for [web sockets](https://developer.mozilla.org/en-US/docs/WebSockets), straight out of the box. As well as the extremely useful [CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete) [blueprint](http://sailsjs.org/#/documentation/reference/blueprint-api) routes, which make [GET](http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods)'in, [POST](http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods)'in & [DELETE](http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods)'in a breeze. What's more, Sails supports these http 'verbs' through the client side web socket SDK [sails.io.js](https://github.com/balderdashy/sails.io.js). Allowing web developers to quickly build real-time applications that leverage the [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events.

Backbone is an extremely popular and incredibly light weight javascript library that

> gives structure to web applications by providing models with key-value binding and custom events, collections with a rich API of enumerable functions, views with declarative event handling

In a nut shell, Backbone gives structure to client side javascript for [single page applications](http://en.wikipedia.org/wiki/Single-page_application). However, Backbone was never built with sockets in mind. Those familiar will know the default `sync` method delegates to [`$.ajax`](http://api.jquery.com/jQuery.ajax/) which itself delegates to [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest). Furthermore, Backbone Model's and Collection's only fire purely clientside events - making it fiddly to respond to server side events on the client.

#### This Plugin

This plugin attempts to bridge the gap between a [Backbone](http://backbonejs.org/#) frontend and a [Sails](http://sailsjs.org/#/) backend. It has it's own Model and Collection class which support syncing over sockets (delegating to [sails.io.js](https://github.com/balderdashy/sails.io.js) internally). Whats more, if the web socket isn't available, there are options to delegate to the original `sync` function.

Perhaps more importantly, this plugin triggers the [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events on client side Model and Collection instances. This allows you to *respond to server side changes* on your models and collections, within the 'Backbone ecosystem'. This ultimately reduces development time, increases maintainability and can serve as a pillar of programming architecture for larger socket based applications.

[Sails](http://sailsjs.org/#/) [blueprints](http://sailsjs.org/#/documentation/reference/blueprint-api) also features great support for [associations](http://sailsjs.org/#/documentation/concepts/ORM/Associations), [population](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) and [filter/sort criteria](http://sailsjs.org/#/documentation/reference/blueprint-api/Find.html). Backbone.Sails has built in functionality that helps streamline these powerful server side features into your Backbone workflow.

#### A quick look at the API...

```javascript
var Address;
var Person = Backbone.Sails.Model.extend({
  modelName: "person",
  assoc: {
    address: function(){ return Address } // function returning address since circular dependence
  },
  config: {
    populate: "address" // populate address by default (on fetch, save, etc)
  }
})
var PersonCollection = Backbone.Sails.Collection.extend({ model: Person })

Address = Backbone.Sails.Model.extend({
  modelName: "address"
  assoc: {
    occupants: PersonCollection
  }
  config: {
    populate: "occupants"
  }
})

var fred = new Person({ name: "fred", address: { street: "maple grove" } });

fred.save(); // will create address and a person, address will be populated

addressRaw = fred.get("address"); // this will grab the raw data for address (a POJO)
address = fred.get("address", true); // passing true will wrap the data with an Address constructor
address.set("number", 4).save();

// fetch is overloaded to call the 'populate' action, resolving with the address as a model
fred.fetch("address").done(function(address){
  var jack = new Person({ name: "jack" })
  address.addTo('occupants', jack) // will call the 'addTo' action, updating both the address and jack
  .done(function(){
    jack.isNew(); // false
    address.get("occupants", true).findWhere({ name:"jack" }); // truthy (since occupants populated)
  })
})

// you can specify filter criteria like this
var persons = new PersonCollection();
persons.query({
  skip: 1,
  limit: 1,
  sort: "name ASC", // an object also works, e.g. { name: 1, street: -1 }
  where: { name: { contains: "a" } }
}).fetch()

// unlike sails, populate can take filter criteria as well
address.populate({
  occupants: {
    limit: 2,
    where: {
      name: "fred"
    }
  }
}).fetch()
```

#### Releases

A [0.1](https://github.com/oscarhaggerty/Backbone.Sails/tree/master/releases/0.1) release is currently available. Sails v0.10 is *required* as well as io.sails v0.9.

#### Dependencies

Backbone.Sails depends on 

* [Sails v0.10](http://sailsjs.org/#/) `npm install sails@^0.10`
* [Backbone](http://backbonejs.org/#)
* [sails.io v0.9](https://github.com/balderdashy/sails.io.js)
* [jQuery](http://jquery.com/)
* [lodash](https://lodash.com/)

The server side blueprints **depend on lodash and bluebird**, so you'll need to run

* `npm install bluebird --save`
* `npm install lodash --save`

#### Integration

* **On The Client**
  
  Include `backbone.sails.js` after it's dependencies have been included. `Backbone.Sails` should be available thereafter.

* **On The Server**
  
  Copy/paste the blueprints folder to `api/blueprints`. The blueprints are backwards compatible with the original sails blueprints.

#### Configuration

Whilst you are familiarizing yourself with the API, I suggest setting the following blueprint options within `config/blueprints.js`:

* `mirror: true`
  
  `mirror` return's socket event's back to the client they originated from - **utterly crucial** for testing/learning and DRY'ing up your front end.
  
* `autowatch: true`
  
  `autowatch` is a flag to the `find` blueprint indicating to subscribe the client to `created` events. A good default is true, whilst your learning. (There is also a configuration option to dynamically flag this on or off from the client with Backbone.Sails)

#### Documentation/Learning

The documentation currently available is:

* [`Backbone.Sails.Model` reference](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/reference/Backbone.Sails.Model.md)
* [`Backbone.Sails.Collection` reference](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/reference/Backbone.Sails.Collection.md)
* [`Backbone.Sails` reference](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/reference/Backbone.Sails.md)
* [Configuration reference](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/reference/Configuration.md)
* [Populating Tutorial](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/tutorial/Populating.md)
* [Syncing Tutorial](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/tutorial/Syncing.md)
* [Adding And Removing Tutorial](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/tutorial/Adding%20%26%20Removing.md)

There is also an example chat client application that can be found [here](https://github.com/oscarhaggerty/Backbone.Sails/tree/master/assets/js/examples/apps/chatclient) that was developed with Backbone.Marionette in coffeescript.

You can also get a good idea of what Backbone.Sails is capable of by looking at the [test code](https://github.com/iahag001/Backbone.Sails/blob/master/assets/tests/backbone.sails.spec.coffee).
