(function() {
  var Promise, actionUtil, _;

  actionUtil = require('./helpers/actionUtil');

  _ = require('lodash');

  Promise = require("bluebird");

  module.exports = function(req, res) {
    var ChildModel, Model, associationAttr, child, childPkAttr, createdChild, parentPk, promises, relation, supposedChildPk;
    Model = actionUtil.parseModel(req);
    relation = req.options.alias;
    if (!relation) {
      res.serverError(new Error('Missing required route option, `req.options.alias`.'));
    }
    parentPk = req.param('parentid');
    associationAttr = _.findWhere(Model.associations, {
      alias: relation
    });
    ChildModel = sails.models[associationAttr.collection];
    childPkAttr = ChildModel.primaryKey;
    child = void 0;
    supposedChildPk = actionUtil.parsePk(req);
    if (supposedChildPk) {
      child = {};
      child[childPkAttr] = supposedChildPk;
    } else {
      child = actionUtil.parseValues(req);
      if (!child) {
        res.badRequest('You must specify the record to add (either the primary key of an existing record to link, or a new object without a primary key which will be used to create a record then link it.)');
      }
      child = actionUtil.flattenAssociations(child, ChildModel);
    }
    createdChild = false;
    promises = {
      parent: new Promise(function(resolve, reject) {
        return Model.findOne(parentPk).exec(function(err, parentRecord) {
          if (err) {
            return reject(err);
          }
          if (!parentRecord) {
            return reject({
              status: 404
            });
          }
          if (!parentRecord[relation]) {
            return reject({
              status: 404
            });
          }
          return resolve(parentRecord);
        });
      }),
      child: new Promise(function(resolve, reject) {
        var createChild;
        createChild = function() {
          return ChildModel.create(child).exec(function(err, newChildRecord) {
            if (err) {
              return reject(err);
            }
            createdChild = true;
            return resolve(newChildRecord);
          });
        };
        if (child[childPkAttr]) {
          return ChildModel.findOne(child[childPkAttr]).exec(function(err, childRecord) {
            if (err) {
              reject(err);
            }
            if (!childRecord) {
              return createChild();
            }
            return resolve(child);
          });
        } else {
          return createChild();
        }
      })
    };
    return Promise.props(promises).error(function(err) {
      return res.negotiate(err);
    }).then(function(data) {
      var coll, err, mirrorAlias;
      if (createdChild) {
        if (req._sails.hooks.pubsub) {
          if (req.isSocket) {
            ChildModel.subscribe(req, data.child);
            ChildModel.introduce(data.child);
          }
          ChildModel.publishCreate(data.child, !req.options.mirror && req);
        }
      }
      try {
        coll = data.parent[relation];
        coll.add(data.child[childPkAttr]);
        if ((mirrorAlias = actionUtil.mirror(Model, relation))) {
          coll = data.parent[mirrorAlias];
          coll.add(data.child[childPkAttr]);
        }
      } catch (_error) {
        err = _error;
        if (err) {
          return res.negotiate(err);
        }
      }
      return data.parent.save(function(err) {
        var isDuplicateInsertError, populate, query, _ref;
        isDuplicateInsertError = (err != null ? (_ref = err[0]) != null ? _ref.type : void 0 : void 0) === 'insert';
        if (err && !isDuplicateInsertError) {
          return res.negotiate(err);
        }
        if (!isDuplicateInsertError && req._sails.hooks.pubsub) {
          Model.publishAdd(data.parent[Model.primaryKey], relation, data.child[childPkAttr], !req.options.mirror && req, {
            noReverse: createdChild
          });
          if ((mirrorAlias = actionUtil.mirror(Model, relation))) {
            Model.publishAdd(data.parent[Model.primaryKey], mirrorAlias, data.child[childPkAttr], !req.options.mirror && req, {
              noReverse: createdChild
            });
          }
        }
        if (createdChild) {
          res.set("created", JSON.stringify(data.child));
        }
        populate = actionUtil.parsePopulate(req);
        if (!populate || _.size(populate) === 0) {
          return res.ok(data.parent);
        }
        query = Model.findOne(parentPk);
        query = actionUtil.populateEach(query, req);
        return query.exec(function(err, parentRecord) {
          if (err) {
            return res.serverError(err);
          }
          if (!parentRecord) {
            return res.serverError();
          }
          if (req._sails.hooks.pubsub && req.isSocket) {
            Model.subscribe(req, parentRecord);
            actionUtil.subscribeDeep(req, parentRecord);
          }
          parentRecord = actionUtil.populateNull(parentRecord, req);
          return res.ok(parentRecord);
        });
      });
    });
  };

}).call(this);
