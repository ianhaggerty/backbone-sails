(function() {
  var actionUtil;

  actionUtil = require('./helpers/actionUtil');

  module.exports = function(req, res) {
    var Model, childPk, parentPk, relation, where;
    Model = actionUtil.parseModel(req);
    relation = req.options.alias;
    if (!relation || !Model) {
      return res.serverError();
    }
    parentPk = req.param('parentid');
    childPk = actionUtil.parsePk(req);
    where = childPk ? [childPk] : actionUtil.parseCriteria(req);
    return Model.findOne(parentPk).populate(relation, {
      where: where,
      skip: actionUtil.parseSkip(req),
      limit: actionUtil.parseLimit(req),
      sort: actionUtil.parseSort(req)
    }).exec(function(err, parentRecord) {
      if (err) {
        return res.serverError(err);
      }
      if (!parentRecord) {
        return res.notFound("No record found with the specified `id`: " + parentPk);
      }
      if (!parentRecord[relation]) {
        return res.notFound("Specified record " + parentPk + " ismissing relation " + relation + ".");
      }
      if (req._sails.hooks.pubsub && req.isSocket) {
        actionUtil.subscribeDeep(req, parentRecord);
      }
      return res.ok(parentRecord[relation]);
    });
  };

}).call(this);
