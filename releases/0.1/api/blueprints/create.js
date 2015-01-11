(function() {
  var Promise, actionUtil, _;

  actionUtil = require('./helpers/actionUtil');

  _ = require('lodash');

  Promise = require("bluebird");

  module.exports = function(req, res) {
    var Model, aliases, data, parsedData, promises;
    Model = actionUtil.parseModel(req);
    data = actionUtil.parseValues(req);
    parsedData = actionUtil.parseData(data, Model);
    promises = {};
    aliases = _.keys(parsedData.associated);
    _.forOwn(parsedData.associated, function(relation, alias) {
      if (relation.create.length) {
        return promises[alias] = new Promise(function(resolve, reject) {
          return relation.Model.create(relation.create).exec(function(err, associatedRecordsCreated) {
            var associatedRecord, ids, _i, _j, _len, _len1;
            if (err) {
              return reject(err);
            }
            if (!associatedRecordsCreated) {
              sails.log.warn('No associated records were created for some reason...');
            }
            if (req._sails.hooks.pubsub) {
              if (req.isSocket) {
                for (_i = 0, _len = associatedRecordsCreated.length; _i < _len; _i++) {
                  associatedRecord = associatedRecordsCreated[_i];
                  relation.Model.introduce(associatedRecord);
                }
              }
              for (_j = 0, _len1 = associatedRecordsCreated.length; _j < _len1; _j++) {
                associatedRecord = associatedRecordsCreated[_j];
                relation.Model.publishCreate(associatedRecord, !req.options.mirror && req);
              }
            }
            ids = _.pluck(associatedRecordsCreated, relation.Model.primaryKey);
            return resolve(ids);
          });
        });
      }
    });
    return Promise.props(promises).error(function(err) {
      if (error) {
        return res.negotiate(err);
      }
    }).then(function(data) {
      var alias, ids, relation, _ref;
      _ref = parsedData.associated;
      for (alias in _ref) {
        relation = _ref[alias];
        ids = (data != null ? data[alias] : void 0) || [];
        parsedData.associated[alias].idsToAdd = _.uniq(parsedData.associated[alias].add.concat(ids));
        if (relation.association.type === 'model' && relation.idsToAdd.length) {
          parsedData.raw[relation.association.alias] = relation.idsToAdd[0];
        }
      }
      return Model.create(parsedData.raw).exec(function(err, newInstance) {
        var id, mirrorAlias, _i, _len, _ref1, _ref2;
        if (err) {
          return res.negotiate(err);
        }
        res.status(201);
        if (req._sails.hooks.pubsub) {
          if (req.isSocket) {
            Model.subscribe(req, newInstance);
            Model.introduce(newInstance);
          }
          Model.publishCreate(newInstance, !req.options.mirror && req);
        }
        if (!aliases.length) {
          newInstance = actionUtil.populateNull(newInstance, req);
          return res.ok(newInstance);
        }
        _ref1 = parsedData.associated;
        for (alias in _ref1) {
          relation = _ref1[alias];
          if (relation.association.type === 'collection') {
            _ref2 = relation.idsToAdd;
            for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
              id = _ref2[_i];
              try {
                newInstance[relation.association.alias].add(id);
                if ((mirrorAlias = actionUtil.mirror(Model, alias))) {
                  newInstance[mirrorAlias].add(id);
                }
              } catch (_error) {
                err = _error;
                if (err) {
                  return res.negotiate(err);
                }
              }
            }
          }
        }
        return newInstance.save(function(err) {
          var populate, query, _j, _k, _len1, _len2, _ref3, _ref4, _ref5;
          if (err) {
            return res.negotiate(err);
          }
          if (req._sails.hooks.pubsub) {
            _ref3 = parsedData.associated;
            for (alias in _ref3) {
              relation = _ref3[alias];
              if (relation.association.type === 'collection') {
                _ref4 = relation.add;
                for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++) {
                  id = _ref4[_j];
                  Model.publishAdd(newInstance[Model.primaryKey], relation.association.alias, id, !req.options.mirror && req);
                }
                if ((mirrorAlias = actionUtil.mirror(Model, alias))) {
                  _ref5 = relation.add;
                  for (_k = 0, _len2 = _ref5.length; _k < _len2; _k++) {
                    id = _ref5[_k];
                    Model.publishAdd(newInstance[Model.primaryKey], mirrorAlias, id, !req.options.mirror && req);
                  }
                }
              }
            }
          }
          populate = actionUtil.parsePopulate(req);
          if (!populate || _.size(populate) === 0) {
            return res.ok(newInstance);
          }
          query = Model.findOne(newInstance[Model.primaryKey]);
          query = actionUtil.populateEach(query, req);
          return query.exec(function(err, populatedRecord) {
            if (err) {
              return res.serverError(err);
            }
            if (req._sails.hooks.pubsub && req.isSocket) {
              actionUtil.subscribeDeep(req, populatedRecord);
            }
            populatedRecord = actionUtil.populateNull(populatedRecord, req);
            return res.ok(populatedRecord);
          });
        });
      });
    });
  };

}).call(this);
