/**
 * Module dependencies
 */
var util = require('util'),
	actionUtil = require('./helpers/actionUtil'),
	_ = require('lodash');



/**
 * Message Records
 *
 *  get   /:modelIdentity
 *   *    /:modelIdentity/find
 *
 * An API call to find a set of models and publish a message to each of them.
 *
 * Optional:
 * @param {Object} where       - the find criteria (passed directly to the ORM)
 * @param {Integer} limit      - the maximum number of records to send back (useful for pagination)
 * @param {Integer} skip       - the number of records to skip (useful for pagination)
 * @param {String} sort        - the order of returned records, e.g. `name ASC` or `age DESC`
 * @param {String} callback - default jsonp callback param (i.e. the name of the js function returned)
 */

module.exports = function messageRecords (req, res) {

	// Look up the model
	var Model = actionUtil.parseModel(req);

	if ( actionUtil.parsePk(req) ) {
		return require('./messageone')(req,res);
	}

	// Lookup for records that match the specified criteria
	var query = Model.find()
		.where( actionUtil.parseCriteria(req) )
		.limit( actionUtil.parseLimit(req) )
		.skip( actionUtil.parseSkip(req) )
		.sort( actionUtil.parseSort(req) );

	query.exec(function found(err, matchingRecords) {
		if (err) return res.serverError(err);

		_.forEach(matchingRecords, function(record){
			Model.message(record, req.body);
		})


		res.ok();
	});
};
