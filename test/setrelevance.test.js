var assert = require('assert');
var getSetRelevance = require('../lib/pure/setrelevance');

describe('getSetRelevance', function() {
    it('works', function() {
        // No matches.
        assert.equal(0.0, getSetRelevance(['georgia','vermont'], []));
        // Relev 1 match for 1 of 2 terms.
        assert.equal(0.5, getSetRelevance(['georgia','vermont'], [
            { id: 153, relev: 1, reason: 1, count: 1, idx: 0, db: 'country', tmpid: 153 }
        ]));
        // Relev 1 match for 2 of 2 terms.
        assert.equal(1, getSetRelevance(['georgia','vermont'], [
            { id: 3553, relev: 1, reason: 2, count: 1, idx: 1, db: 'province', tmpid: 100000000003553 },
            { id: 130305, relev: 1, reason: 1, count: 1, idx: 2, db: 'place', tmpid: 300000000130305 }
        ]));
        // Relev penalized for 2 of 2 terms, but with a gap in db index.
        assert.equal(0.99, getSetRelevance(['georgia','vermont'], [
            { id: 3553, relev: 1, reason: 2, count: 1, idx: 1, db: 'province', tmpid: 100000000003553 },
            { id: 130305, relev: 1, reason: 1, count: 1, idx: 3, db: 'place', tmpid: 300000000130305 }
        ]));
        // Second match for the same reason does not contribute to final relevance.
        assert.equal(0.5, getSetRelevance(['georgia','vermont'], [
            { id: 153, relev: 1, reason: 1, count: 1, idx: 0, db: 'country', tmpid: 153 },
            { id: 130305, relev: 1, reason: 1, count: 1, idx: 3, db: 'place', tmpid: 300000000130305 }
        ]));
        // Second match with the same DB does not contribute to final relevance.
        assert.equal(0.5, getSetRelevance(['georgia','vermont'], [
            { id: 130305, relev: 1, reason: 1, count: 1, idx: 3, db: 'place', tmpid: 300000000130305 },
            { id: 8062, relev: 1, reason: 2, count: 1, idx: 3, db: 'place', tmpid: 300000000008062 }
        ]));
        // Repeated terms with fittable counts/db indexes.
        assert.equal(1, getSetRelevance(['new','york','new','york'], [
            { id: 1, relev: 1, reason: 15, count: 2, idx: 2, db: 'province', tmpid: 300000000000001 },
            { id: 2, relev: 1, reason: 15, count: 2, idx: 3, db: 'place', tmpid: 300000000000002 }
        ]));
        // Repeated terms but match counts are exhausted.
        assert.equal(0.5, getSetRelevance(['new','york','new','york','new','york','new','york'], [
            { id: 1, relev: 1, reason: 255, count: 2, idx: 2, db: 'province', tmpid: 300000000000001 },
            { id: 2, relev: 1, reason: 255, count: 2, idx: 3, db: 'place', tmpid: 300000000000002 }
        ]));
    });
});
