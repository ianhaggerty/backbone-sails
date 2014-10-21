|*This library is a work in progress. I was planning on a release sooner, but I haven't been satisfied with the API as of yet. The glue code between these two libraries it proving more tedious than previously hoped!*

---

Backbone.Sails
==============

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

var Address = Backbone.Sails.Model.extend({
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
  address.addTo('occupants', jack); // will call the 'addTo' action, updating both the address and jack
  jack.isNew(); // false
  address.get("occupants", true).findWhere({ name:"jack" }); // truthy (since occupants populated)
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

A [0.1 beta](https://github.com/iahag001/Backbone.Sails/tree/master/releases/0.1beta) release is currently available. Sails 0.10 is required.

#### Dependencies

Backbone.Sails depends on 

* [Backbone](http://backbonejs.org/#)
* [Sails](http://sailsjs.org/#/) (0.10 or above)
* [jQuery](http://jquery.com/)
* [lodash](https://lodash.com/)
* [sails.io](https://github.com/balderdashy/sails.io.js)

#### Integration

**On the client**, include `backbone.sails.js` after it's dependencies have been included. `Backbone.Sails` should be available thereafter.

**On the server**, copy/paste the blueprints folder to `api/blueprints`. The blueprints are backwards compatible with the original sails blueprints.

