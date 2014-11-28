# Backbone.Sails v0.1

***

# `Backbone.Sails`
### @type Object

Used internally to track the state of the application.

## Methods

* `configure(options)`

  This function is used to set configuration options at the global level.

* `connected()`

  This function returns a boolean indicating whether a persistent web socket connection has been established.

* `connecting()`

  This function returns a `Promise` (by default, a jQuery promise) which resolves when a web socket connection is established:
  
  ```
  Backbone.Sails.connecting().done(function(){
    // handle web socket connection event
  })
  ```

## Properties

* `config`

  This is an object where the global configuration options are held.

* `Models`

  This is an object which maintains 'event aggregators' for Backbone.Sails. It is used internally for the most part. It may be helpful, however, for debugging purposes.
 