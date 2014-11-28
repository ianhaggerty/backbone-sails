# Backbone.Sails Configuration v0.1

***

* ### [Configuration Levels](#configuration-levels-1)

  * ### [Global Level](#global-level)

  * ### [Constructor Level](#constructor-or-class-level)
  
  * ### [Instance Level](#instance-level-1)
  
  * ### [Request Level](#request-level-1)
  
* ### [Configuration Options](#configuration-options-1)

  * ### [`eventPrefix`](#eventprefix-1)
  
  * ### [`populate`](#populate-1)
  
  * ### [`where`](#where-1)
  
  * ### [`limit`](#limit-1)
  
  * ### [`skip`](#skip-1)
  
  * ### [`sort`](#sort-1)
  
  * ### [`watch`](#watch-1)
  
  * ### [`prefix`](#prefix)
  
  * ### [`sync`](#sync-1)
  
  * ### [`timeout`](#timeout-1)
  
  * ### [`poll`](#poll-1)
  
  * ### [`client`](#client-1)
  
  * ### [`promise`](#promise-1)
  
  * ### [`log`](#log-1)
  
  * ### [`state`](#state-1)
  
***

## Configuration Levels

Backbone.Sails has a number of additional configuration options. Some of the configuration options can be 'inherited', in that, there are four 'levels' at which configuration options can be set:

* #### Global Level

  To set at the *global level*, use the `Backbone.Sails.configure()` function. This can take an object or a key-val pair. This is the uppermost level of configuration, and can be used to set some helpful defaults:
  
  ```javascript
  Backbone.Sails.configure({
    // default number of records to return from the 'find' blueprint
    limit: 30,
    
    // wrap's jQuery promises returned from the library
    // this example return's a bluebird promise
    promise: function(p){
      return Promise.resolve(p);
    }
  });
  ```

* #### Constructor (or Class) Level

  To set at the *constructor level*, you can pass a `config` object within the `Model` or `Collection` declaration:
  
  ```javascript
  var Model = Backbone.Sails.Model.extend({
      
    config {
      sync: 'socket ajax subscribe set'
    }
      
  })
  ```
  
* #### Instance Level

  To set at the *instance level*, simply pass the relevant configuration options as part of the `options` object the standard backbone [`Model`](http://backbonejs.org/#Model-constructor) and [`Collection`](http://backbonejs.org/#Collection-constructor) constructors take:
  
  ```javascript
  var model = new Model({
    // attrs
  }, {
    // config
    populate: 'friends'
  })
  ```
* #### Request Level

  To set at the *request level*, simply pass the relevant configuration options as part of the `options` object:
  
  ```javascript
  // force a sync over the socket
  coll.fetch({ sync: 'socket' })
  ```

**Note**: not all configuration options can be set at *all* levels. Some can only be set at the *global* level, for example.

Any configuration option can be overridden at a lower level. If you'd like to completely nullify an inherited configuration option, you can pass `false` as the value:

```javascript
Backbone.Sails.configure({
  limit: 30
})
coll.fetch({
  limit: false // no limit
})
```

## Configuration Options

All the Backbone.Sails configuration options are referenced here.

_The **@level** tag indicates the levels at which the option can be set._

* ### `eventPrefix`
  
  **@type** `String`
  
  **@default** `""`
  
  **@level** *global | constructor | instance*
  
  This is a string to prefix all of the additional event identifier's emitted by Backbone.Sails. This is particularly useful if the event identifier's are clashing with your own, or, if you'd like some more clarity as to the fact that they are socket based events:
  
  ```javascript
  Backbone.Sails.configure({
    eventPrefix: 'socket' // 'socket:' also works
  })
  someModel.on('socket:updated:name', function(m, v, e){
    // handle update event
    someModel.set('name', v);
  })
  ```
  
* ### `populate`

  **@type** `String` | `Array` | `Object`
  
  **@default** `false`
  
  **@level** *global | constructor | instance | request*
  
  This is the criteria to be sent directly to the waterline ORM, specifying exactly what attributes should be populated. The criteria can be a simple string, with an attribute (or a number of space delimited attributes). It can also be an array of attributes or, to get more specific, you can pass an object of filter criteria:
  
  ```javascript
  coll.fetch({
    populate: {
      users: {
        where: {
          name: { contains: { 'Fred' } }
        },
        limit: 10
      }
    }
  })
  
  user.fetch({
    populate: 'friends bestFriend'
  })
  ```
  
* ### `where`

  **@type** `Object`
  
  **@default** `false`
  
  **@level** *global | constructor | instance | request*
  
  This is the filter criteria used to return records from the `find` blueprint. It is relevant when fetching collections. The filter criteria is passed directly to the waterline ORM, the documentation of which can be found [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).
  
  ```javascript
  coll.fetch({
    where: {
      name: { '!' : ['Walter', 'Skyler'] }
    }
  })
  ```
  
* ### `limit`

  **@type** `Number`
  
  **@default** `30`
  
  **@level** *global | constructor | instance | request*
  
  This option is used to limit the number of records returned from a collection's `fetch` request.
  
* ### `skip`

  **@type** `Number`
    
  **@default** `false`
  
  **@level** *global | constructor | instance | request*
  
  This option is used to skip a number of results. When combined with the `sort` and `limit` options, you can easily implement pagination:
  
  ```javascript
  var Coll = Backbone.Sails.Collection.extend({
    config: {
      limit: 10,
      sort: 'name ASC'
    },
    
    fetchPage: function(page){
      return this.fetch({
        skip: page * this.config.limit
      })
    }
  })
  ```
  
* ### `sort`

  **@type** `Number` | `Object`
      
  **@default** `false`
  
  **@level** *global | constructor | instance | request*
  
  This is the sort criteria to be passed straight into waterline. It can be a string: `"name ASC"`, `"lName DESC"`. Or it can be an object: `sort: { lName: 1, age: -1 }` (`"lName"` ascending, `"age"` descending). It is documented [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).
  
* ### `watch`

  **@type** `Boolean`
        
  **@default** `true`
  
  **@level** *global | constructor | instance | request*
  
  This is a flag to the Sails backend to indicate whether to `watch` for `"created"` event's on the table being fetched. It is equivalent to the sails blueprint option [`autoWatch`](http://sailsjs.org/#/documentation/reference/sails.config/sails.config.blueprints.html) - the only difference being, `watch` can act as a dynamic flag on a per-request basis:
  
  ```javascript
  var Coll = Backbone.Sails.Collection({
    modelName: 'user'
    config: {
      watch: false;
    }
  });
  coll.fetch({ watch: true }); // will subscribe
  
  // coll can now receive 'created' events
  coll.on('created', function(data, e){ // handle })
  
  // if no longer interested, send another fetch request ('watch' is false from constructor config)
  coll.fetch()
  ```
  
  Take great care when using this option - if the collection referenced is highly transient, any client's subscribed will be notified of any new record's created, which could end up being a huge burden on your server.
  
* ### `prefix`

  **@type** `String`
          
  **@default** `""`
  
  **@level** *global*
  
  This is equivalent the Sails blueprint option [`prefix`](http://sailsjs.org/#/documentation/reference/sails.config/sails.config.blueprints.html).
  
  ```javascript
  Backbone.Sails.configure({
    prefix: '/api'
  })
  ```
  
* ### `sync`

  **@type** `String` | `Array`
        
  **@default** `['socket', 'ajax', 'subscribe']`
  
  **@level** *global | constructor | instance | request*
  
  This is an important option which configures how to best leverage web sockets to sync and subscribe your models. The full scope of the this option is covered in the [syncing tutorial](https://github.com/oscarhaggerty/Backbone.Sails/blob/master/docs/0.1/tutorial/Syncing.md):
  
  > The `sync` option looks for the following strings: `ajax`, `socket`, `subscribe` & `set`.
     
  > If `ajax` is present, the implementation will sync over ajax. More precisely, it'll delegate to *whatever sync function is found on the instance*. This is usually just the default `Backbone.sync`, however, you can change it as you will, giving you complete control.
  >
  > If `socket` is present, the implementation will wait for the socket to connect, before syncing over sockets.
  >
  >If both `ajax` and `socket` are present, the implementation will sync over socket's if available, delegating to ajax if not.
  >
  > If `ajax`, `socket` and `subscribe` are present, the implementation will re-send ajax delegated requests over sockets, to ensure subscription as soon as possible.
  
  > If `ajax`, `socket`, `subscribe` and `set` are present, the implementation will `set()` the models to the updated state of the record, when the socket-subscription requests respond. This is useful if you want to ensure the most up-to-date version of the instance, before beginning to respond to socket events.
  
  Here's a fairly typical dialog:
  
  ```javascript
  // user enters website, fetch messages
  messages.fetch({
    sync: ['socket', 'ajax', 'subscribe', 'set']
  }).done(function(){
    // will delegate to ajax initially
    // sockets still connecting
    // handle page render
  })
  // implementation will re-send request over socket's, 'set'ing to the updated state
  // we'll need to handle the 'change' event's from backbone
  messages.on('change', function(){
    // re-render relevant parts of page
    
    // set up listeners to handle socket events
  })
  ```
  
* ### `timeout`
  
  **@type** `Number`
          
  **@default** `false`
  
  **@level** *global*
  
  The `timeout` option configures how long to wait for a socket request before timing out. It should be set to a number in milliseconds (~ 2000 is a good recommendation). It is **only relevant for socket only requests**. A request over the socket will reject if the socket connection is not established after `timeout` milliseconds. When it rejects, the promise will reject with parameters `(timeout, method, instance, options)`
  
  ```javascript
  Backbone.Sails.configure({
    timeout: 2000
  })
  model.fetch({ sync: 'socket' }).fail(function(time){
    if(typeof time == 'number') {
      // handle timeout
    }
  })
  ```
  
* ### `poll`

  **@type** `Number`
            
  **@default** `50`
  
  **@level** *global*
  
  `poll` is used internally to determine how long to poll for certain boolean functions to return true. A typical case is polling for a `connected` state from web sockets.
  
* ### `client`

  **@type** `Function`
              
  **@default** `function(){ return io.socket; }`
  
  **@level** *global*
  
  This is a function which return's the *socket client*. The socket client interface must subscribe to the interface provided by [sails.io.js](http://sailsjs.org/#/documentation/reference/websockets/sails.io.js).
  
* ### `promise`

  **@type** `Function`
                
  **@default** `function(p){ return p; }`
  
  **@level** *global*
  
  This is a function that you can configure to wrap all promises consumed & produced by the API. It takes a jQuery promise as a first argument, and should return the promise that you wish to use. Here are some typical examples:
  
  ```javascript
  Backbone.Sails.configure({
    promise: function(p) { return Q(p); } // Q promises
  })
  ```
  ```javascript
  Backbone.Sails.configure({
    promise: function(p) { return Promise.resolve(p); } // Bluebird promises
  })
  ```
* ### `log`

  **@type** `Boolean`
                  
  **@default** `true`
  
  **@level** *global*
  
  This is a simple boolean to indicate whether to log socket requests and warnings to the console. Useful for development, but should be turned off for production.
  
* ### `state`

  **@type** `String`
                  
  **@default** `"client"`
  
  **@level** *global | constructor | instance | request*
  
  This is a special boolean indicating how the `message` method should behave on a collection. It configures which `state` of the collection to `message`. If the `state` is `"client"`, it will message all models currently residing in the client side `state` of the collection. If the `state` is `"server"`, it will message all models that would be returned within the next `fetch` request (as configured via the filter criteria `where`, `limit`, `sort`, `skip`).