### Syncing

Whilst ordinary Backbone models work pretty well with a Sails backend, they don't delegate to persisting over sockets. Persisting over sockets is generally much quicker and also subscribes the client to server side changes on the record persised. `Backbone.Sails.Model`, will, with the default configuration, persist over sockets, if available.

An important difference between using Backbone models and Backbone.Sails models is that you pass `modelName` property as opposed to a `urlRoot` or a `url` property. The `modelName` is the same identifier used server side - the one used by sails to generate blueprint routes.

```javascript
var User = Backbone.Sails.Model.extend({
  // this is the same model identifier used server side
  // it is case insensitive
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

Fetching over ajax, however, doesn't subscribe the client to server side changes on the records fetched. Backbone.Sails (by default) will send another socket request, when the socket connects, to subscribe the records initially fetched over ajax.

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

When the implementation sends the socket request, it will receive the same response from the ajax request, however, with the updated state of the records. Backbone.Sails provides an option to update the models with this updated state, if so desired.

#### Configuring Sync

The `sync` option is used to configure how Backbone.Sails model & collections classes sync with the server. The `sync` option is a space delimited string, or an array, of flags telling Backbone.Sails how to behave. It can be set at all levels configuration. At the global level, constructor (or class) level, instance & request level.

The `sync` option looks for the following strings: `ajax`, `socket`, `subscribe` & `set`. They are fairly self-explanatory given the above text.

If `ajax` is present, the implementation will sync over ajax. More precisely, it'll delegate to *whatever sync function is found on the model*. This is usually just the default `Backbone.sync`, however, you can change it as you will, giving you complete control.

If `socket` is present, the implementation will wait for the socket to connect, before syncing over sockets.

If both `ajax` and `socket` are present, the implementation will sync over socket's if available, delegating to ajax if not.

If `ajax`, `socket` and `subscribe` are present, the implementation will re-send ajax delegated requests over sockets, to ensure subscription as soon as possible.

If `ajax`, `socket`, `subscribe` and `set` are present, the implementation will `set()` the models to the updated state of the record, when the socket-subscription requests respond.

#### Subscription

Those familiar with the standard Sails blueprints will know that they subscribe to pretty much everything touched on the server side - including models sent, received, populated... everything. This is no doubt to satisfy the many clientside libraries integrating with the backend. However, Backbone.Sails adopts the philosophy that *only records returned in server responses will be subscribed*. This includes populated records and any *new* records created via the `add` blueprint action (since that comes back via a header regardless of the populate option).

By it's very nature, this should be of little concern to you for the most part. Where it may be relevant, is when you are creating models purely from i.d. string's returned in the response (an associated model, say):

```javascript
jack = new Person({ spouse: { name: "Jane" } })
jack.save().done(function(){ // will respond will Jane's id as `spouse` attribute
  jane = new Person({ id: jack.get("spouse") })
  
  // jane is not currently subscribed, since she wasn't populated in the POST request
})
```

This would be much better anyhow:

```javascript
jack = new Person({ spouse: { name: "Jane" } })
jack.populate("spouse").save().done(function(){ // Jane is populated, she is subscribed

  jane = jack.get("spouse", true);
  
  // jane is subscribed, we can listen for comet events
  jane.on("updated:spouse", function(){
    beginLegalCustodyProceedings()
  })
})
```

#### Timeout

There is a global configuration option `timeout`, which can be set to tell the implementation how long to wait for a socket connection (in milliseconds), before rejecting a request. By default it is `false`, indicating to never give up - this mean's purely socket based requests (no ajax delegation) will wait indefinitely for a socket connection before resolving or rejecting - a potentially dangerous behaviour.

By setting `timeout` to a numeric value (2000 = two seconds), your requests to `fetch()`, `save()` etc, may reject on the basis that the request timed out (again - if there is no ajax delegation). If these methods do reject because of the request timing out, the promise will reject with `(timeout, method, instance, options)`.
