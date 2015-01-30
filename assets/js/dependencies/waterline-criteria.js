(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
// See http://stackoverflow.com/a/3143231/486547
    module.exports = /(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d+([+-][0-2]\d:[0-5]\d|Z))|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z))|(\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z))/;

},{}],2:[function(require,module,exports){
    /**
     * Module dependencies
     */



    /**
     * Apply a `limit` modifier to `data` using `limit`.
     *
     * @param  { Object[] }  data
     * @param  { Integer }    limit
     * @return { Object[] }
     */
    module.exports = function (data, limit) {
        if( limit === undefined || !data || limit === 0) return data;
        return _.first(data, limit);
    };

},{}],3:[function(require,module,exports){
    /**
     * Module dependencies
     */



    /**
     * Apply a `skip` modifier to `data` using `numToSkip`.
     *
     * @param  { Object[] }  data
     * @param  { Integer }   numToSkip
     * @return { Object[] }
     */
    module.exports = function (data, numToSkip) {

        if(!numToSkip || !data) return data;

        // Ignore the first `numToSkip` tuples
        return _.rest(data, numToSkip);
    };

},{}],4:[function(require,module,exports){
    /**
     * Module dependencies
     */

    var X_ISO_DATE = require('../X_ISO_DATE.constant');



    /**
     * Apply a(nother) `where` filter to `data`
     *
     * @param  { Object[] }  data
     * @param  { Object }    where
     * @return { Object[] }
     */
    module.exports = function (data, where) {
        if( !data ) return data;
        return _.filter(data, function(tuple) {
            return matchSet(tuple, where);
        });
    };






//////////////////////////
///
/// private methods   ||
///                   \/
///
//////////////////////////


// Match a model against each criterion in a criteria query
    function matchSet(model, criteria, parentKey) {

        // Null or {} WHERE query always matches everything
        if(!criteria || _.isEqual(criteria, {})) return true;

        // By default, treat entries as AND
        return _.all(criteria, function(criterion, key) {
            return matchItem(model, key, criterion, parentKey);
        });
    }


    function matchOr(model, disjuncts) {
        var outcomes = [];
        _.each(disjuncts, function(criteria) {
            if(matchSet(model, criteria)) outcomes.push(true);
        });

        var outcome = outcomes.length > 0 ? true : false;
        return outcome;
    }

    function matchAnd(model, conjuncts) {
        var outcome = true;
        _.each(conjuncts, function(criteria) {
            if(!matchSet(model, criteria)) outcome = false;
        });
        return outcome;
    }

    function matchLike(model, criteria) {
        for(var key in criteria) {
            // Return false if no match is found
            if (!checkLike(model[key], criteria[key])) return false;
        }
        return true;
    }

    function matchNot(model, criteria) {
        return !matchSet(model, criteria);
    }

    function matchItem(model, key, criterion, parentKey) {

        // Handle special attr query
        if (parentKey) {

            if (key === 'equals' || key === '=' || key === 'equal') {
                return matchLiteral(model,parentKey,criterion, compare['=']);
            }
            else if (key === 'not' || key === '!') {

                // Check for Not In
                if(Array.isArray(criterion)) {

                    var match = false;
                    criterion.forEach(function(val) {
                        if(compare['='](model[parentKey], val)) {
                            match = true;
                        }
                    });

                    return match ? false : true;
                }

                return matchLiteral(model,parentKey,criterion, compare['!']);
            }
            else if (key === 'greaterThan' || key === '>') {
                return matchLiteral(model,parentKey,criterion, compare['>']);
            }
            else if (key === 'greaterThanOrEqual' || key === '>=')  {
                return matchLiteral(model,parentKey,criterion, compare['>=']);
            }
            else if (key === 'lessThan' || key === '<')  {
                return matchLiteral(model,parentKey,criterion, compare['<']);
            }
            else if (key === 'lessThanOrEqual' || key === '<=')  {
                return matchLiteral(model,parentKey,criterion, compare['<=']);
            }
            else if (key === 'startsWith') return matchLiteral(model,parentKey,criterion, checkStartsWith);
            else if (key === 'endsWith') return matchLiteral(model,parentKey,criterion, checkEndsWith);
            else if (key === 'contains') return matchLiteral(model,parentKey,criterion, checkContains);
            else if (key === 'like') return matchLiteral(model,parentKey,criterion, checkLike);
            else throw new Error ('Invalid query syntax!');
        }
        else if(key.toLowerCase() === 'or') {
            return matchOr(model, criterion);
        } else if(key.toLowerCase() === 'not') {
            return matchNot(model, criterion);
        } else if(key.toLowerCase() === 'and') {
            return matchAnd(model, criterion);
        } else if(key.toLowerCase() === 'like') {
            return matchLike(model, criterion);
        }
        // IN query
        else if(_.isArray(criterion)) {
            return _.any(criterion, function(val) {
                return compare['='](model[key], val);
            });
        }

        // Special attr query
        else if (_.isObject(criterion) && validSubAttrCriteria(criterion)) {
            // Attribute is being checked in a specific way
            return matchSet(model, criterion, key);
        }

        // Otherwise, try a literal match
        else return matchLiteral(model,key,criterion, compare['=']);

    }

// Comparison fns
    var compare = {

        // Equalish
        '=' : function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] == x[1];
        },

        // Not equalish
        '!' : function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] != x[1];
        },
        '>' : function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] > x[1];
        },
        '>=': function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] >= x[1];
        },
        '<' : function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] < x[1];
        },
        '<=': function (a,b) {
            var x = normalizeComparison(a,b);
            return x[0] <= x[1];
        }
    };

// Prepare two values for comparison
    function normalizeComparison(a,b) {

        if(_.isUndefined(a) || a === null) a = '';
        if(_.isUndefined(b) || b === null) b = '';

        if (_.isString(a) && _.isString(b)) {
            a = a.toLowerCase();
            b = b.toLowerCase();
        }

        // If Comparing dates, keep them as dates
        if(_.isDate(a) && _.isDate(b)) {
            return [a.getTime(), b.getTime()];
        }
        // Otherwise convert them to ISO strings
        if (_.isDate(a)) { a = a.toISOString(); }
        if (_.isDate(b)) { b = b.toISOString(); }


        // Stringify for comparisons- except for numbers, null, and undefined
        if (!_.isNumber(a)) {
            a = typeof a.toString !== 'undefined' ? a.toString() : '' + a;
        }
        if (!_.isNumber(b)) {
            b = typeof b.toString !== 'undefined' ? b.toString() : '' + b;
        }

        // If comparing date-like things, treat them like dates
        if (_.isString(a) && _.isString(b) && a.match(X_ISO_DATE) && b.match(X_ISO_DATE)) {
            return ([new Date(a).getTime(), new Date(b).getTime()]);
        }

        return [a,b];
    }

// Return whether this criteria is valid as an object inside of an attribute
    function validSubAttrCriteria(c) {

        if(!_.isObject(c)) return false;

        var valid = false;
        var validAttributes = [
            'equals', 'not', 'greaterThan', 'lessThan', 'greaterThanOrEqual', 'lessThanOrEqual',
            '<', '<=', '!', '>', '>=', 'startsWith', 'endsWith', 'contains', 'like'];

        _.each(validAttributes, function(attr) {
            if(hasOwnProperty(c, attr)) valid = true;
        });

        return valid;
    }

// Returns whether this value can be successfully parsed as a finite number
    function isNumbery (value) {
        if(_.isDate(value)) return false;
        return Math.pow(+value, 2) > 0;
    }

// matchFn => the function that will be run to check for a match between the two literals
    function matchLiteral(model, key, criterion, matchFn) {

        var val = _.cloneDeep(model[key]);

        // If the criterion are both parsable finite numbers, cast them
        if(isNumbery(criterion) && isNumbery(val)) {
            criterion = +criterion;
            val = +val;
        }

        // ensure the key attr exists in model
        if(!model.hasOwnProperty(key)) return false;
        if(_.isUndefined(criterion)) return false;

        // ensure the key attr matches model attr in model
        if((!matchFn(val,criterion))) {
            return false;
        }

        // Otherwise this is a match
        return true;
    }


    function checkStartsWith (value, matchString) {
        // console.log('CheCKING startsWith ', value, 'against matchString:', matchString, 'result:',sqlLikeMatch(value, matchString));
        return sqlLikeMatch(value, matchString + '%');
    }
    function checkEndsWith (value, matchString) {
        return sqlLikeMatch(value, '%' + matchString);
    }
    function checkContains (value, matchString) {
        return sqlLikeMatch(value, '%' + matchString + '%');
    }
    function checkLike (value, matchString) {
        // console.log('CheCKING  ', value, 'against matchString:', matchString, 'result:',sqlLikeMatch(value, matchString));
        return sqlLikeMatch(value, matchString);
    }

    function sqlLikeMatch (value,matchString) {

        if(_.isRegExp(matchString)) {
            // awesome
        } else if(_.isString(matchString)) {
            // Handle escaped percent (%) signs
            matchString = matchString.replace(/%%%/g, '%');

            // Escape regex
            matchString = escapeRegExp(matchString);

            // Replace SQL % match notation with something the ECMA regex parser can handle
            matchString = matchString.replace(/([^%]*)%([^%]*)/g, '$1.*$2');

            // Case insensitive by default
            // TODO: make this overridable
            var modifiers = 'i';

            matchString = new RegExp('^' + matchString + '$', modifiers);
        }
        // Unexpected match string!
        else {
            console.error('matchString:');
            console.error(matchString);
            throw new Error('Unexpected match string: ' + matchString + ' Please use a regexp or string.');
        }

        // Deal with non-strings
        if(_.isNumber(value)) value = '' + value;
        else if(_.isBoolean(value)) value = value ? 'true' : 'false';
        else if(!_.isString(value)) {
            // Ignore objects, arrays, null, and undefined data for now
            // (and maybe forever)
            return false;
        }

        // Check that criterion attribute and is at least similar to the model's value for that attr
        if(!value.match(matchString)) {
            return false;
        }
        return true;
    }

    function escapeRegExp(str) {
        return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
    }



    /**
     * Safer helper for hasOwnProperty checks
     *
     * @param {Object} obj
     * @param {String} prop
     * @return {Boolean}
     * @api public
     */

    var hop = Object.prototype.hasOwnProperty;
    function hasOwnProperty(obj, prop) {
        return hop.call(obj, prop);
    }

},{"../X_ISO_DATE.constant":1}],5:[function(require,module,exports){
    /**
     * Module dependencies
     */


    window.WC = _.extend(

        // Provide all-in-one top-level function
        require('./query'),

        // but also expose direct access
        // to all filters and projections.
        {
            where: require('./filters/where'),
            limit: require('./filters/limit'),
            skip: require('./filters/skip'),
            sort: require('./sort'),

            // Projections and aggregations are not-yet-officially supported:
            groupBy: require('./projections/groupBy'),
            select: require('./projections/select')

            // Joins are currently supported by Waterline core:
            // , populate : require('./projections/populate')
            // , leftJoin : require('./projections/leftJoin')
            // , join     : require('./projections/join')
            // , rightJoin : require('./projections/rightJoin')

        });
},{"./filters/limit":2,"./filters/skip":3,"./filters/where":4,"./projections/groupBy":6,"./projections/select":7,"./query":8,"./sort":9}],6:[function(require,module,exports){
    /**
     * Module dependencies
     */


    /**
     * Partition the tuples in `filteredData` into buckets via `groupByAttribute`.
     * Works with aggregations to allow for powerful reporting queries.
     *
     * @param  { Object[] }  filteredData
     * @param  { String }    groupByAttribute
     * @return { Object[] }
     */
    module.exports = function (filteredData, groupByAttribute) {
        return filteredData;
    };

},{}],7:[function(require,module,exports){
    /**
     * Module dependencies
     */


    /**
     * Project `tuples` on `fields`.
     *
     * @param  { Object[] }  tuples    [i.e. filteredData]
     * @param  { String[]/Object{} }  fields    [i.e. schema]
     * @return { Object[] }
     */
    function select (tuples, fields) {

        // Expand splat shortcut syntax
        if (fields === '*') {
            fields = { '*': true };
        }

        // If `fields` are not an Object or Array, don't modify the output.
        if (typeof fields !== 'object') return tuples;

        // If `fields` are specified as an Array, convert them to an Object.
        if (_.isArray(fields)) {
            fields = _.reduce(fields, function arrayToObj(memo, attrName) {
                memo[attrName] = true;
                return memo;
            }, {});
        }

        // If the '*' key is specified, the projection algorithm is flipped:
        // only keys which are explicitly set to `false` will be excluded--
        // all other keys will be left alone (this lasts until the recursive step.)
        var hasSplat = !!fields['*'];
        var fieldsToExplicitlyOmit = _(fields).where(function _areExplicitlyFalse (v,k){ return v === false; }).keys();
        delete fields['*'];


        // Finally, select fields from tuples.
        return _.map(tuples, function (tuple) {

            // Select the requested attributes of the tuple
            if (hasSplat) {
                tuple = _.omit(tuple, function (value, attrName){
                    return _.contains(fieldsToExplicitlyOmit, attrName);
                });
            }
            else {
                tuple = _.pick(tuple, Object.keys(fields));
            }


            // || NOTE THAT THIS APPROACH WILL CHANGE IN AN UPCOMING RELEASE
            // \/ TO MATCH THE CONVENTIONS ESTABLISHED IN WL2.

            // Take recursive step if necessary to support nested
            // SELECT clauses (NOT nested modifiers- more like nested
            // WHEREs)
            // 
            // e.g.:
            // like this:
            //   -> { select: { pet: { collarSize: true } } }
            //   
            // not this:
            //   -> { select: { pet: { select: { collarSize: true } } } }
            //
            _.each(fields, function (subselect, attrName) {

                if (typeof subselect === 'object') {
                    if (_.isArray(tuple[attrName])) {
                        tuple[attrName] = select(tuple[attrName], subselect);
                    }
                    else if (_.isObject(tuple[attrName])) {
                        tuple[attrName] = select([tuple[attrName]], subselect)[0];
                    }
                }
            });

            return tuple;
        });
    }

    module.exports = select;

},{}],8:[function(require,module,exports){
    /**
     * Module dependencies
     */

    var _where = require('./filters/where');
    var _limit = require('./filters/limit');
    var _skip = require('./filters/skip');
    var _select = require('./projections/select');
    var _groupBy = require('./projections/groupBy');
    var _sort = require('./sort');



    /**
     * Filter/aggregate/partition/map the tuples known as `classifier`
     * in `data` using `criteria` (a Waterline criteria object)
     *
     * @param  { Object[] }           data
     * @param  { Object }             criteria         [the Waterline criteria object- complete w/ `where`, `limit`, `sort, `skip`, and `joins`]
     *
     * @return { Integer | Object | Object[] }
     */

    module.exports = function query ( /* classifier|tuples, data|criteria [, criteria] */ ) {

        // Embed an `INDEX_IN_ORIG_DATA` for each tuple to remember its original index
        // within `data`.  At the end, we'll lookup the `INDEX_IN_ORIG_DATA` for each tuple
        // and expose it as part of our results.
        var INDEX_IN_ORIG_DATA = '.(ørigindex)';

        var tuples, classifier, data, criteria;

        // If no classifier is provided, and data was specified as an array
        // instead of an object, infer tuples from the array
        if (_.isArray(arguments[0]) && !arguments[2]) {
            tuples = arguments[0];
            criteria = arguments[1];
        }
        // If all three arguments were supplied:
        // get tuples of type `classifier` (i.e. SELECT * FROM __________)
        // and clone 'em.
        else {
            classifier = arguments[0];
            data = arguments[1];
            criteria = arguments[2];
            tuples = data[classifier];
        }

        // Clone tuples to avoid dirtying things up
        tuples = _.cloneDeep(tuples);

        // Embed `INDEX_IN_ORIG_DATA` in each tuple
        _.each(tuples, function(tuple, i) {
            tuple[INDEX_IN_ORIG_DATA] = i;
        });

        // Ensure criteria object exists
        criteria = criteria || {};

        // Query and return result set using criteria
        tuples = _where(tuples, criteria.where);
        tuples = _sort(tuples, criteria.sort);
        tuples = _skip(tuples, criteria.skip);
        tuples = _limit(tuples, criteria.limit);
        tuples = _select(tuples, criteria.select);

        // TODO:
        // tuples = _groupBy(tuples, criteria.groupBy);

        // Grab the INDEX_IN_ORIG_DATA from each matched tuple
        // this is typically used to update the tuples in the external source data.
        var originalIndices = _.pluck(tuples, INDEX_IN_ORIG_DATA);

        // Remove INDEX_IN_ORIG_DATA from each tuple--
        // it is no longer needed.
        _.each(tuples, function(tuple) {
            delete tuple[INDEX_IN_ORIG_DATA];
        });

        return {
            results: tuples,
            indices: originalIndices
        };
    };


},{"./filters/limit":2,"./filters/skip":3,"./filters/where":4,"./projections/groupBy":6,"./projections/select":7,"./sort":9}],9:[function(require,module,exports){
    /**
     * Module dependencies
     */

    var X_ISO_DATE = require('./X_ISO_DATE.constant');



    /**
     * Sort the tuples in `data` using `comparator`.
     *
     * @param  { Object[] }  data
     * @param  { Object }    comparator
     * @param  { Function }    when
     * @return { Object[] }
     */
    module.exports = function(data, comparator, when) {
        if (!comparator || !data) return data;

        // Equivalent to a SQL "WHEN"
        when = when||function rankSpecialCase (record, attrName) {

            // null ranks lower than anything else
            if ( typeof record[attrName]==='undefined' || record[attrName] === null ) {
                return false;
            }
            else return true;
        };

        return sortData(_.cloneDeep(data), comparator, when);
    };



//////////////////////////
///
/// private methods   ||
///                   \/
///                   
//////////////////////////






    /**
     * Sort `data` (tuples) using `sortVector` (comparator obj)
     *
     * Based on method described here:
     * http://stackoverflow.com/a/4760279/909625
     *
     * @param  { Object[] } data         [tuples]
     * @param  { Object }   sortVector [mongo-style comparator object]
     * @return { Object[] }
     */

    function sortData(data, sortVector, when) {

        // Constants
        var GREATER_THAN = 1;
        var LESS_THAN = -1;
        var EQUAL = 0;

        return data.sort(function comparator(a, b) {
            return _(sortVector).reduce(function (flagSoFar, sortDirection, attrName){


                var outcome;

                // Handle special cases (defined by WHEN):
                var $a = when(a, attrName);
                var $b = when(b, attrName);
                if (!$a && !$b) outcome = EQUAL;
                else if (!$a && $b) outcome = LESS_THAN;
                else if ($a && !$b) outcome = GREATER_THAN;

                // General case:
                else {
                    // Coerce types
                    $a = a[attrName];
                    $b = b[attrName];
                    if ( $a < $b ) outcome = LESS_THAN;
                    else if ( $a > $b ) outcome = GREATER_THAN;
                    else outcome = EQUAL;
                }

                // Less-Than case (-1)
                // (leaves flagSoFar untouched if it has been set, otherwise sets it)
                if ( outcome === LESS_THAN ) {
                    return flagSoFar || -sortDirection;
                }
                // Greater-Than case (1)
                // (leaves flagSoFar untouched if it has been set, otherwise sets it)
                else if ( outcome === GREATER_THAN ) {
                    return flagSoFar || sortDirection;
                }
                // Equals case (0)
                // (always leaves flagSoFar untouched)
                else return flagSoFar;

            }, 0);
        });
    }






    /**
     * Coerce a value to its probable intended type for sorting.
     *
     * @param  {???} x
     * @return {???}
     */
    function coerceIntoBestGuessType (x) {
        switch ( guessType(x) ) {
            case 'booleanish': return (x==='true')?true:false;
            case 'numberish': return +x;
            case 'dateish': return new Date(x);
            default: return x;
        }
    }


    function guessType (x) {

        if (!_.isString(x)) {
            return typeof x;
        }

        // Probably meant to be a boolean
        else if (x === 'true' || x === 'false') {
            return 'booleanish';
        }

        // Probably meant to be a number
        else if (+x === x) {
            return 'numberish';
        }

        // Probably meant to be a date
        else if (x.match(X_ISO_DATE)) {
            return 'dateish';
        }

        // Just another string
        else return typeof x;
    }

},{"./X_ISO_DATE.constant":1}]},{},[5]);
