### Adding to and removing from an Associated Collections

#### `addTo` and `removeFrom`

Sails provides the usual CRUD methods (create, read, update, delete) to interact with records. However it also provides an `add` action as well as a `remove` action. These actions serve to **addTo** or **removeFrom** an associated collection.

Consider the following model:

```javascript
// Person.js
module.exports = {
  attributes: {
    name: "string",
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

We would create the corresponding client side model:

```javascript
Person = Backbone.Sails.Model.extend({
  modelName: "person",
  assoc: {
    parents: function(){ return PersonCollection; },
    children: function(){ return PersonCollection; }
  }
})
PersonCollection = Backbone.Sails.Collection.extend({
  model: Person
})
```

Since the model/collection's are so simple, we could also declare the associations like this, without any loss of functionality:

```javascript
Person = Backbone.Sails.Model.extend({
  modelName: "person",
  assoc: {
    spouse: ["person"],
    children: ["person"]
  }
})
```

For the `Person` model above, Sails will provide (in addition to the usual CRUD routes) the blueprint routes to interact with the associated records:

* GET `/person/:id/spouse`      = [`populate`](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) blueprint
* GET `/person/:id/children`    = [`populate`](http://sailsjs.org/#/documentation/reference/blueprint-api/Populate.html) blueprint
* POST `/person/:id/children`   = [`add`](http://sailsjs.org/#/documentation/reference/blueprint-api/Add.html)      blueprint
* DELETE `/person/:id/children` = [`remove`](http://sailsjs.org/#/documentation/reference/blueprint-api/Remove.html)   blueprint

Taking advantage of this functionality is tedious in a normal Backbone Model. `Backbone.Sails.Model` provides two methods to streamline the addition and removal of records from associated collections: `addTo` and `removeFrom`.
 
Both these methods will act a bit like `save()`, in that they update the state of the record being added to, when the response is received. However, instead of sending a body down as part of a PUT request, they will send down a model (or just a model id) to be added or removed.

*Note:* `addTo` does not ever **change** the state of the record being added, it will create new records if necessary, and then add the `id` to the associated collection. If you add an existing record to an associated collection, it will not update that record. If you add a record yet to be created, it will create it and then add it. If you add a record yet to be created, that has its own associated records to be created, *they will not be created*. Consider this when writing your [policies](http://sailsjs.org/#/documentation/concepts/Policies).

Let's take a look at some examples...


```javascript
var john = new Person({ name: "John" });

// john is not new, so has no `id`
// which means we cannot `addTo` children
// (although we could send the children associations down with the POST request)

john.save().done(function(){
  // john now has id, we can `addTo`
  
  // before we do, let's configure the `populate` option at the *instance level*
  // so that we receive the `children` collection in the response when we `addTo`
  john.populate("children") // convenience for `john.configure("populate", "children")`
  
  // `addTo` takes two parameters, a key and a {Model}model|{Object}attributes|{String}id
  addingJack = john.addTo('children', { name: 'Jack' });
  
  addingJack.done(function(johnData){
      // johnData is server response used to update john
      // the `children` collection will be populated as part of the response
      // we can get the raw data
      childrenRaw = john.get("children");
      
      // or we can wrap is with a collection passed in the model definition
      children = john.get("children", true);
      
      // we can then find jack
      jack = john.findWhere({ name: "Jack" })
      
      // and remove him, for example
      john.removeFrom('children', jack);
    })
  
  // this time we'll add a model
  var jill = new Person({ name: 'Jill' });
  
  // Since Jill model is new, Jill model will also be updated when the response is received
  // this as achieved using a special header (not part of ordinary sails)
  // this is necessary since the response is tailored according to `populate` criteria
  addingJill = john.addTo('children', jill);
  
  addingJill.done(function(){
    
    // john model has now been updated with the response
    // jill model has new been updated as well (will not have any populated attributes)
    jill.isNew(); // false
    jill.id; // truthy
    
    // jill isnt populated, let's make a request to get her parents
    jill.populate("parents").fetch().done(function(){
      
      // we could re-acquire jack like this
      jack = jill.get("parents", true).findWhere({ name: "John" })
      
      // although - he wouldn't be populated, you get the idea!
      
    })
  })
})
```

#### POST'ing & PUT'ing Associated Collections

As suggested above, when you are creating a record, you can also create the associated record's at the same time. You simply send them down as part of the post request:

```javascript
jack = new Person({ name: "Jack", children: [{ name: "Stephanie" }] })

// calling save will create both Jack and Stephanie records
jack.save()
```

You cannot, however, doubly nest associations to be created:

```javascript
jack = new Person({ name: "Jack", children: [{ name: "Stephanie", parents: [{ name: "Jill" }] }] })

// This will save, but Jill will not be created
jack.save()
```

You can, however, pass id's *or* existing model/attribute hashes as part of a double nest:

```javascript
// save Jill first
jill = new Person({ name: "Jill" })
jill.save().done(function(){
  jack = new Person({ name: "Jack", children: [{ name: "Stephanie", parents: [jill.id] }] })
  
  // This will save, but Jill will not be created
  jack.save()
})
```

*Please Note*, for the 0.1 release, the `addedTo` events may not be fired with a double nest. (For the above example, Jill's `children` would have been added to.).

If you want to work with the associated records created, you can configure what is returned from the POST using the populate query parameter:

```javascript
mum = new Person({ name: "Jane" })
mum.set("children", [{ name: "Donna" }, { name: "Jack" }, { name: "John" }, { name: "Miguel" }])

// we could get all the created children back
mum.populate("children")
mum.save()

// we can also filter them
mum.populate({
  children: {
    name: {
      contains: "a"
    }
  }
})
mum.save().done(function(){
  childrenRaw = mum.get("children") // ray array of Donna & Jack records (with id's)
})
```

