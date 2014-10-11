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

Backbone.Sails aims to be minimal, introducing only the necessary functionality, whilst adhering to established Backbone conventions where possible.

#### Dependencies

Backbone.Sails depends on 

* [Backbone](http://backbonejs.org/#)
* [Sails](http://sailsjs.org/#/) (0.10 or above)
* [jQuery](http://jquery.com/)
* [lodash](https://lodash.com/)
* [sails.io](https://github.com/balderdashy/sails.io.js)

#### Integration

**On the client**, include `backbone.sails.js` after it's dependencies have been included. `Backbone.Sails` should be available thereafter.

**On the server**, copy/paste the blueprints folder to `api/blueprints`. Sails delegates these custom blueprints if they are specified. *Very little* has been changed to the core Sails blueprints. The only non-compatible change (sails 0.10) is that the `add` and `remove` blueprints **now return the record added or removed, not the record added to or removed from**.

### Getting Started

#### CRUD'ing with Models

Whilst ordinary Backbone models work pretty well with a Sails backend, they don't delegate to persisting over sockets. Persisting over sockets is generally much quicker and also subscribes the client to server side changes on the record persised. `Backbone.Sails.Model`, will, with the default configuration, persist over sockets, if available.

An important difference between using Backbone models and Backbone.Sails models is that you pass `modelName` property as opposed to a `urlRoot` or a `url` property. The `modelName` is the same identifier used server side - the one used by sails to generate blueprint routes.

```javascript
var User = Backbone.Sails.Model.extend({
  // this is the same model identifier used server side
  // is is case insensitive
  modelName: "user" 
  
  // no `urlRoot` necessary
  // it will be created for you
});

var user = new User({
  fName: "Bob"
  lName: "Bingham"
});

// if socket connected, will persist over sockets
user.save();
```

`io.socket` typically takes 2-3 seconds to connect to the server initially. For most websites, this delay will be unacceptable. Fortunately, Backbone.Sails will (by default) delegate to ajax, if the socket isn't available, allowing your users to view the page quicker:

```javascript
Backbone.Sails.connected(); // false

messages = new Messages();

// `fetch` will delegate to ajax, if sockets aren't available, by default
messages.fetch().then(function(){
  // handle success
});
```

Fetching over ajax, however, doesn't subscribe the client to server side changes on the records fetched. Backbone.Sails (by default) will 'fire back' a socket request to subscribe the records fetched over ajax.

```javascript
messages.fetch().then(function() {
  // once the fetch request is fired back over sockets
  // the messages fetched will be subscribed to server side changes
  messages.on('updated:content', function(message, content){
    // this will trigger Backbone's 'change'
    message.set("content", content); 
  });
  // handle the change event
  messages.on("change:content", handleContentChange);
})
```

When the socket 'fires back', if there has been any change to the record since the ajax request resolved, these changes (by default) will be `set` on your model. So be prepared to handle the `change` events if you want to update your user interface to the updated state of the record.

This behaviour (understandably) may not be desired. If you don't want `set` to be called when the request 'fires back' over the socket, you can pass the configuration option `fireback: false`:

```javascript
Backbone.Sails.connected(); // false

// will only `set` on the first (ajax) request
user.fetch({ fireback: false });
```

The `fireback` option can be set at the *request* level, the *instance* level, the *constructor* level, or the *global* level:

You may not want to use socket's at all. You can configure the `sync` option to indicate to Backbone.Sails what strategy you'd like to take. The `sync` option looks for the strings `"socket"` or `"ajax"` or both. The `sync` option can be set at the *request* level, the *instance* level, the *constructor* level, or the *global* level:

```javascript
// configure `sync` at the *global* level
Backbone.Sails.configure({ sync: "socket" });

var User = Backbone.Sails.Model.extend({
  // a config object is used to configure at the *constructor* level
  config: {
    sync: "socket ajax"
  }
})

// pass in the `options` object to configure at the *instance* level
var user = new User({ fName: "Bob" }, { sync: ['ajax'] })

// pass in the `options` object to configure at the *request* level
user.fetch({ sync: ['socket'] })
```

Ajax requests will resolve or reject pretty quickly, depending in the server response. However, socket *only* requests will wait for the socket to become available before attempting to make the request. By default, a socket request will timeout after 5 seconds, rejecting the promise returned. You can change this by configuring the `timeout` option:

```javascript
Backbone.Sails.configure({
  timeout: 2000 // after two seconds
});
```

The `timeout` option can only be configured at the *global* level. You can set it to `false` to wait indefinitely for the socket to connect before resolving socket-only requests. Bare in mind, this will also queue up 'fire-back' socket requests, which also depend on the timeout to reject. Whatever strategy you choose, you should always be prepared to handle a rejected promise, as the server may reject the request in any case.

```javascript
data.save({}, { sync: 'socket' }); // may timeout and reject after 2 seconds
```

#### Populating Models

Sails has the concept of 'population' baked into its Waterline ORM. Population is a term used to describe the retrieval of records which are *associated* to the original record. These associations, with respect to the original record, may be of a **to-many** relation or a **to-one** relation. Population is not concerned with the *reverse-association*.

Consider the following model:

```javascript
// Person.js
module.exports = {
  attributes: {
    fName: "string",
    spouse: {
      model: 'Person'
    }
    children: {
      collection: 'Person'
    }
  }
};
```

In this example, a `Person` *may* have a **single** spouse, and they *may* have **many** children. To get a single person, Sails will generate (if blueprints are enabled) the route `/person/:id`. By default, sails will not populate with the associated records. You can explicitly request an attribute to be populated by passing the `populate` query parameter: `/person/:id?populate=spouse`. This will return a single person, with the `spouse` attribute populated. That is, `spouse` will be an object of attributes representing the `spouse` record. You can request multiple attributes to be populated using a comma delimited query parameter: `/person/:id?populate=spouse,children`. The attribute `children` will now also be populated with an *array* of `Person` objects representing the children (the above assumes that policies are configured to allow the `populate` action to be called).

Needless to say, this functionality can be extremely useful, especially for the rendering of views of nested structures. It is however, a little tedious to incorporate into Backbone. Backbone.Sails introduces the `populate` configuration option. The `populate` option can be set at the *global* level, the *constructor* level, the *instance* level and the *request* level to configure what attributes are populated in the server response.

```javascript
Backbone.Sails.configure({ populate: 'user' }); // global level

var Person = Backbone.Sails.Model.extend({
  modelName: 'person',
  config: {
    populate: 'spouse' // constructor level
  }
});

var person = new Person({ id: "123" });

// use the `query` (or `configure`) method to set at the instance level
// will override the constructor level
person.query('populate', 'children'); 

person.fetch(); // will populate children

// request level
person.fetch({ populate: 'children spouse' }) // will populate children and spouse
person.fetch({ populate: ['children', 'spouse'] }); // this also works (a little faster)
```

The populated attributes will be available as on the `person` instance as an object or an array of objects. You can create a model or collection from the populated attributes if desired:

```javascript
children = new PersonCollection(person.get("chlidren"));
spouse = new Person(person.get("spouse"))

spouse.set("spouse", person.id);
spouse.save(); // this'll finish setting up the one-to-one association
```

#### AddingTo and RemovingFrom an Associated Collection

Sails provides the usual CRUD methods (create, read, update, delete) to interact with records. However it also provides an `add` action as well as a `remove` action. These actions serve to **addTo** or **removeFrom** an associated collection. For the `Person` model above, Sails will provide the blueprint routes to interact with the associated records:

* GET `/person/:id/spouse`      = `populate` blueprint
* GET `/person/:id/children`    = `populate` blueprint
* POST `/person/:id/children`   = `add`      blueprint
* DELETE `/person/:id/children` = `remove`   blueprint

Taking advantage of this functionality it tedious in a normal Backbone Model. `Backbone.Sails.Model` provides the two methods to streamline the additiona and removal of records from associated collections: `addTo` and `removeFrom`. These methods **do not mutate `model.attributes`**, instead, they make a *request* to the server. `addTo` will POST to (for e.g.) `/person/:id/children` where as `removeFrom` will DELETE to `/person/:id/children`. Both methods return a promise which resolves with the server response data.

```javascript
var husband = new Person({ fName: "John" })

// husband isNew() so cannot addTo yet...

husband.save().done(function(){
  // husband now has id, we can `addTo`
  
  // `addTo` takes two parameters, a key and a model/attribute hash
  promiseOne = husband.addTo('children', { fName: 'Jack' });
  var jill = new Person({ fName: 'Jill' });
  promiseTwo = husband.addTo('children', jill);
  
  promiseOne.done(function(jackData){
    // jackData is server response
    // we can create a jack model from it
    
    jack = new Person(jackData);
    
    // and then do stuff with jack
    // like disowning him...
    
    husband.removeFrom('children', jack);
  })
})
```

#### Updating Models with Populated Attributes
*(Is generally a bad thing to do)*

Calling `save` on a model will send a POST or PUT request to the server with the `model.attributes` JSONified as the body. This means that **any populated attributes** will go down as part of the POST or PUT request:

```javascript
person = new Person({ fName: "John" });
person.set("spouse", { fName: "Jen" });

// since person.attributes.spouse is a POJO with no `id`
// sails will create a `person` model for "Jen" and update
// the `spouse` attribute for "John"
// this will call action `create` once, waterline does the rest
person.save();

// assuming the response has not been populated
// person.attributes.spouse will now be "Jen"'s `id`

// we can either populate 'test' before the request goes down or fetch again with 'test' populated
```

Persisting nested models this way can a great convenience. However, it can be difficult to secure with policies, doesn't always fire the resourceful pub/sub events you'd expect and can even crash sails if you use it in the wrong way.

For example, following on from the code above, if you were to run:
```javascript
person.set("spouse", { fName: "Janet" });

person.save();
```
the request **actually crashes Sails** (0.10).

Saving associated collections is quite unpredictable as well:

```javascript
person.set("tests", [{ fName: "Jack" }, { fName: "Fred" }])

// upon save
// on the client: 'tests' will dissapear on the model if not populated
// on the server: the two `Person` instances will be created and added to the associated collection
// however, these instances don't seem to subscribe (v0.10 of sails)
person.save()

// we can do this again
person.set("tests", [{ fName: "Jack" }, { fName: "Fred" }])

// upon save
// on the server: since no id's were passed, sails considers these two models new
// it will create the models, and add them to the associated collection
// **however**, the behaviour of sails(0.10) is to remove any previous records
// from the associated collection when updating this way
// no removedFrom or addedTo events will be fired when persisting associated collections this way (0.10)
person.save()

// on the brightside, sails doesn't crash when you do this
```

Soooo... if your going to persist associated collections this way, don't expect the records added or removed to be subscribed, and don't expect the 'addedTo' or 'removedFrom' events to fire. If your going to persist associated models (to-one relations), only do so if you are creating a new record in the first place.

**As a rule of thumb**, only send down associated attributes as part of a request if you are creating a brand new model in the first place (HTTP POST). Do not send populated attributes down if you are updating a record:

```javascript
// data for husband
husband = new Person({
  fName: "John",
  spouse: {
    fName: "Janet"
  },
  children: {
    { fName: "Jack" },
    { fName: "Jill" }
  }
})

husband.isNew(); // true
husband.save(); // this is ok

// server will respond with no populations (if configured)
// meaning children array no longer exists clientside and
// 'spouse' is now just an id
husband.attributes; // { fName: "John", spouse: "123anid456" }

// you can always grab the wife
wife = new Person({ id: husband.get("spouse") })
wife.fetch();
```

If you want to access the children, you can use an **associated collection** (see later).



