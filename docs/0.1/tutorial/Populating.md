### Populating Models

Sails has the concept of 'population' baked into its Waterline ORM. Population is a term used to describe the retrieval of records which are *associated* to the original record. These associations, with respect to the original record, may be of a **to-many** relation or a **to-one** relation. Population is not concerned with the *reverse-association*.

Consider the following model:

```javascript
// Person.js
module.exports = {
  attributes: {
    name: "string",
    spouse: {
      model: "Person",
      via: "spouse"
    },
    parents: {
      model: 'Person',
      via: "children"
    }
    children: {
      collection: 'Person',
      via: "parents",
      dominant: true
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

// request level - pass `populate` in the options hash
person.fetch({ populate: 'children spouse' }) // will populate children and spouse
person.fetch({ populate: ['children', 'spouse'] }); // this also works (a little faster)
```

Since populating is very common, there is also a convenience function, `populate`, to configure at the instance level:

```javascript
jack = new Person({ name: "Jack", parents: [{ name: "John" }] })
jack.populate("parents")
jack.save() // response will contain parents array
```

#### *Populating is a big part of Backbone.Sails*

In Backbone.Sails, populating is a way of tailoring exactly the kind of response you want from the server. It applies to `save()`, `fetch()`, `addTo()` & `removeFrom()`. You are telling the server what you want as part of the response, and this response is always used to `set()` or update the model/collection on which it is being called - so it is of great importance.

Being such an important option, there are many ways you can configure what to populate. The `populate` option can simply be a space-delimited string, with the attributes to populate: `person.populate("children parents")`. You can also pass an array if preferred, or a comma delimited string or a JSONified array string. For associated collections, this will populate the collections referenced indefinitely - there is no limit to the number of records returned within the associated collection when configuring populate this way, so be wary.

`populate` can also be an object with the keys as attributes. A key can be set to `true`, or you can set it to an object of filter criteria to be passed to waterline on the backend:

```javascript
jill = new Person({ name: "Jill" })
jack = new Person({ name: "Jack", spouse: jill, children: [{ name: "Jack" }, { name: "John" }, { name: "Jane" }, { name: "June" }, { name: "Janet" }, { name: "Julius" }] })
jack.populate({
  children: {
    limit: 5,
    sort: "name ASC",
    where: { name: { contains: "J" } },
    skip: 1
  }
})
jack.save() // response will contain 5 children
```

The criteria passed goes directly into Waterline on the server side, giving you a lot of room to configure the response. A detailed overview of these options can be found [here](https://github.com/balderdashy/waterline-docs/blob/master/query-language.md).


#### Populating with `fetch()`

Sails actually has an independent `populate` blueprint designed specifically to return associated record(s). For the person model defined above, the following routes would be generated:

* GET `/person/:id/parents`     = [`populate`](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) blueprint
* GET `/person/:id/children`    = [`populate`](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) blueprint
* GET `/person/:id/spouse`    = [`populate`](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) blueprint

Backbone.Sails overloads `fetch()` to allow you to take advantage of this action. `fetch()` normally takes a single optional options object, however, you can pass a string as the first argument to make a request to populate a certain attribute. This response from the server is the populated attribute alone - meaning there is no update to the model on which `fetch()` is called, it instead resolves a promise with the associated model as the first argument. An example should clear things up:

```javascript
jill = new Person({ id: "123" });

// let's populate jill's spouse without necessarily getting jill
jill.fetch("spouse").done(function(spouse){
  
  // here, spouse will be a `Person` model, representing Jill's spouse
  spouse.set("spouse", null)
  spouse.save() // a divorce
  
})
```

You cannot further populate the `populate` action. So there are no options to populate the response this way. You can, however, specify filter criteria for associated collections. Therefore, you can pass filter criteria as part of the `options` object to `fetch()` in order to tailor the response:

```javascript
jill = new Person({ id: "123" });

jill.fetch("children", { limit: 3, where: { name: { startsWith: "I" } } }).done(function(children){

  ian = children.findWhere({ name: "Ian" })
  
  ian.set("name", "Oscar")
  ian.save()

})
```

When fetching a populated associated collection in this manner, the collection returned will have it's `url` determined via it's `modelName` attribute. If you want to fetch the updated state of the associated collection, you'll have to issue another populate request, or, you can set the url of the collection to the corresponding `populate` action url, and issue a fetch from there:

```javascript
jill = new Person({ id: "123" });

jill.fetch("children").done(function(children){

  // if we want to know about any addition or removal of children
  // we'll have to `jill.fetch("children")` again, or we can manufacture the `url`
  children.url = "/person/" + jill.id + "/children"
  children.fetch() // calls populate action on the server

})
```

It is worth bearing in mind that `fetch()` normally resolves with `(response, statusCode, xhr)`. The overloaded `fetch(attr, options)` will resolve with `(instance, response, statusCode, xhr)`, where instance is either an associated model or collection.
