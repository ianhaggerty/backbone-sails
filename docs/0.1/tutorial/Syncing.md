#### Syncing with Models

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
