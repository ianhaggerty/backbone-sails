module.exports =
  attributes:
    name: "string"
    value: "integer"

    tests:
      collection: "test"
      via: "test"
    test:
      model: "test"
      via: "tests"

    friends:
      collection: "test"
      via: "friendsTo"
      dominant: true
    friendsTo:
      collection: "test"
      via: "friends"

    mates:
      collection: "test"
      via: "_mates"
      dominant: true
    _mates:
      collection: "test"
      via: "mates"