var config = require('./config');

config.payouts.sort(function(a, b) {
	if (a.probability < b.probability) return 1;
	if (a.probability > b.probability) return -1;
	return 0;
});

var probabilityTotal = config.payouts.reduce(function(a, b) { return a + b.probability}, 0);

var spawnValue = function() {
	var num = Math.random() * probabilityTotal,
		ceil = 0,
		floor,
		i = 0,
		numPayouts = config.payouts.length;
	
	for (i; i < numPayouts; i++) {
		floor = ceil;
		ceil += config.payouts[i].probability;

		if (floor <= num && num < ceil) return config.payouts[i].symbol;
	}

	return config.payouts[i].symbol;
};

var checkWins = function() {

};

var spin = function() {

};

module.exports = spin;