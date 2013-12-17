module.exports = {
	targetFPS: 60,
	width: 500,
	height: 400,
	background: '/images/bg.png',
	buttons: {
		src: '/images/buttons_sheet.png',
		spin: {
			sheet: {
				width: 100,
				height: 50,
				x: 0,
				y: 0,
				frames: 5
			},
			position: {
				x: 215,
				y: 325
			}
		},
		arrows: {
			sheets: {
				up: {
					width: 15,
					height: 25,
					x: 0,
					y: 75,
					frames: 5
				},
				down: {
					width: 15,
					height: 25,
					x: 0,
					y: 50,
					frames: 5
				}
			},
			positions: {
				decreaseLines: {
					x: 10,
					y: 338
				},
				increaseLines: {
					x: 50,
					y: 338
				},
				decreaseBet: {
					x: 75,
					y: 338
				},
				increaseBet: {
					x: 115,
					y: 338
				}
			}
		}
	},
	fields: {
		lines: {
			font: "12px Helvetica",
			color: "#000000",
			x: 37,
			y: 350
		},
		bet: {
			font: "12px Helvetica",
			color: "#000000",
			x: 102,
			y: 350
		},
		totalBet: {
			font: "12px Helvetica",
			color: "#000000",
			x: 172,
			y: 350
		},
		win: {
			font: "12px Helvetica",
			color: "#000000",
			x: 360,
			y: 350
		},
		balance: {
			font: "12px Helvetica",
			color: "#000000",
			x: 448,
			y: 350
		}
	},
	symbols: {
		src: '/images/symbols_sheet.png',
		width: 100,
		height: 100
	},
	reel: {
		width: 100,
		height: 300,
		regX: 0,
		regY: 0,
		spinDuration: 0.4,
		spinDelay: 0.5,
		speed: 2000
	},
	payouts: [
		{
			symbol: 0,
			probability: 5,
			wins: [30, 125, 400]
		}, {
			symbol: 1,
			probability: 5,
			wins: [20, 100, 300]
		}, {
			symbol: 2,
			probability: 5,
			wins: [15, 75, 200]
		}, {
			symbol: 3,
			probability: 5,
			wins: [10, 50, 150]
		}, {
			symbol: 4,
			probability: 5,
			wins: [5, 20, 100]
		}, {
			symbol: 5,
			probability: 5,
			wins: [5, 20, 100]
		}, {
			symbol: 6,
			probability: 5,
			wins: [5, 20, 100]
		}, {
			symbol: 7,
			probability: 5,
			wins: [5, 20, 100]
		}, {
			symbol: 8,
			probability: 1,
			wins: [40, 200, 750]
		}, {
			symbol: 9,
			probability: 1,
			wins: [50, 300, 1000]
		}
	],
	lines: [
		[1, 1, 1, 1, 1],
		[2, 2, 2, 2, 2],
		[0, 0, 0, 0, 0],
		[2, 1, 0, 1, 2],
		[0, 1, 2, 1, 0],
		[0, 0, 1, 0, 0],
		[2, 2, 1, 2, 2],
		[1, 2, 2, 2, 1],
		[1, 0, 0, 0, 1],
		[0, 1, 1, 1, 0],
		[2, 1, 1, 1, 2],
		[0, 1, 0, 1, 0],
		[2, 1, 2, 1, 2],
		[1, 0, 1, 0, 1],
		[1, 2, 1, 2, 1],
		[1, 1, 0, 1, 1],
		[1, 1, 2, 1, 1],
		[0, 2, 0, 2, 0],
		[2, 0, 2, 0, 2],
		[1, 0, 2, 0, 1],
		[1, 2, 0, 2, 1],
		[0, 0, 2, 0, 0],
		[2, 2, 0, 2, 2],
		[0, 2, 2, 2, 0],
		[2, 0, 0, 0, 2],
		[0, 2, 1, 2, 0],
		[2, 0, 1, 0, 2],
		[0, 0, 1, 2, 2],
		[2, 2, 1, 0, 0],
		[1, 0, 1, 2, 1]
	]
};