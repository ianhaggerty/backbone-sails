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
