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
