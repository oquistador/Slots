var config = require('./config/server_config');

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

var checkWins = function(values, wager) {
	var results = {},
		lineIdx,
		linesLength = config.lines.length,
		line,
		matches,
		matchValue,
		multiplier,
		reelIdx,
		symbolIdx,
		symbol,
		prize;

	results.reward = 0;
	results.wins = [];

	for (lineIdx = 0; lineIdx < wager.lines && lineIdx < linesLength; lineIdx++) {
		matches = [];
		line = config.lines[lineIdx];
		matchValue = values[0][line[0]];
		multiplier = 1;

		for (reelIdx = 0; reelIdx <= 4; reelIdx++) {
			symbolIdx = line[reelIdx];
			
			symbol = {
				value: values[reelIdx][symbolIdx],
				position: [reelIdx, symbolIdx]
			};

			if (symbol.value == matchValue || symbol.value > 7 || matchValue > 7) {
				matches.push(symbol);
			} else {
				break;
			}

			if (symbol.value == 9) {
				multiplier++;
			}

			if (symbol.value <= 7) {
				matchValue = symbol.value
			}
		}

		if (matches.length >= 3) {
			prize = config.payouts.filter(function(payout) { return payout.symbol == matchValue})[0].wins[matches.length - 3];
			prize *= multiplier;

			results.reward += prize;
			results.wins.push({line: lineIdx, matches: matches});
		}
	}

	results.values = values;
	results.reward *= wager.bet;

	return results;
};

module.exports = function(wager) {
	var values = [],
		reelIdx = 0,
		symbolIdx = 0;

	for (reelIdx; reelIdx <= 4; reelIdx++) {
		for (symbolIdx = 0; symbolIdx <= 2; symbolIdx++) {
			if (!values[reelIdx]) {
				values[reelIdx] = []
			}

			values[reelIdx][symbolIdx] = spawnValue();
		}
	}

	return checkWins(values, wager);
};