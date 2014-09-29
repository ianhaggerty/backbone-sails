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

Perhaps more importantly, this plugin triggers the [resourceful pub/sub](http://sailsjs.org/#/documentation/reference/websockets/resourceful-pubsub) events on client side Model and Collection instances. This allows you to *respond to server side changes* on your models and collections, within the 'Backbone ecosystem'. This ultimately reduces development time, increases maintainability and serves as an architectural pillar for larger socket based applications.

[Sails](http://sailsjs.org/#/) [blueprints](http://sailsjs.org/#/documentation/reference/blueprint-api) also feature great support for [associations](http://sailsjs.org/#/documentation/concepts/ORM/Associations), [population](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) and [filter/sort criteria](http://sailsjs.org/#/documentation/reference/blueprint-api/Find.html). Backbone.Sails has methods and options that make working using these features easier and much more readable.

#### Getting Started

*more coming soon!*
