Slots = {}

Slots.config = 
	targetFPS: 60
	width: 500
	height: 400
	symbol: 
		src: '/images/symbols_sheet.png'
		width: 100
		height: 100
	reel:
		width: 100
		height: 300
		regX: 0
		regY: 0
		spinDuration: 0.4
		spinDelay: 0.5
		speed: 2000
	calculator:
		payouts: [
			{symbol: 0, probability: 5, wins: [50, 300, 1000]}
			{symbol: 1, probability: 10, wins: [40, 200, 750]}
			{symbol: 2, probability: 10, wins: [30, 100, 500]}
			{symbol: 3, probability: 10, wins: [20, 50, 300]}
			{symbol: 4, probability: 30, wins: [10, 40, 200]}
			{symbol: 5, probability: 30, wins: [5, 25, 100]}
			{symbol: 6, probability: 30, wins: [5, 25, 100]}
			{symbol: 7, probability: 30, wins: [5, 25, 100]}
			{symbol: 8, probability: 10, wins: [50, 300, 1000]}
			{symbol: 9, probability: 5, wins: [400, 1200, 4000]}
		]

Slots.load = ->
	canvas = document.createElement 'canvas'
	canvas.width = @config.width
	canvas.height = @config.height

	document.body.appendChild canvas

	@stage = new createjs.Stage canvas
	
	manifest = [
		id: 'symbols', src: @config.symbol.src
	]

	@loader = new createjs.LoadQueue false
	@loader.addEventListener 'complete', @init
	@loader.loadManifest manifest

Slots.init = =>
	Slots.calculator = new Slots.Calculator
	Slots.symbolBuilder = new Slots.SymbolBuilder
	Slots.state = new Slots.State

	createjs.Ticker.timingMod = createjs.Ticker.RAF_SYNCHED
	createjs.Ticker.setFPS Slots.config.targetFPS
	createjs.Ticker.addEventListener 'tick', Slots.state.tick

class Slots.Calculator
	constructor: (opts)->
		config = {}
		
		_.extend config, Slots.config.calculator, opts

		@payouts = config.payouts
		
		@payouts.sort (a, b)->
			return 1 if a.probability < b.probability
			return -1 if a.probability > b.probability
			0

		@probabilityTotal = @payouts.reduce ((a, b)-> a + b.probability), 0

	spawnValue: ->
		num = Math.random() * @probabilityTotal
		
		ceil = 0
		for payout in @payouts
			floor = ceil
			ceil += payout.probability

			return payout.symbol if floor <= num < ceil

		payout.symbol

	getSpinResults: (opts)->
		defer = $.Deferred()
		results = {}
		results.values = []

		for i in [0..4]
			for j in [0..2]
				results.values[i] = [] unless results.values[i]
				results.values[i][j] = @spawnValue()

		setTimeout (-> defer.resolve results), 500

		defer.promise()

class Slots.State
	constructor: ->
		@reels = []
		
		for i in [0..4]
			@reels[i] = new Slots.Reel position: i
			Slots.stage.addChild @reels[i].container

		@spin()

	spin: ->
		reel.startSpin() for reel in @reels
		Slots.calculator.getSpinResults().done @handleSpinResults

	handleSpinResults: (results)=>
		for reel, i in @reels
			reel.completeSpin values: results.values[i]

	tick: (evt)=>
		deltaS = evt.delta / 1000
		@reels.forEach (reel)-> reel.update deltaS

		Slots.stage.update evt
		return

class Slots.Reel
	isSpinning: false

	constructor: (opts)->
		config = {}

		_.extend config, Slots.config.reel, opts

		@spinDuration = config.spinDuration
		@spinDelay = config.spinDelay
		@position = config.position
		@speed = config.speed

		@container = new createjs.Container
		@container.y = config.regY
		@container.x = config.position * config.width + config.regX
		@container.width = config.width
		@container.height = config.height
		@container.name = "reel#{@position}"

		@blurFilter = new createjs.BlurFilter 0, 10, 1

		for i in [0..3]
			symbol = Slots.symbolBuilder.newSprite()
			symbol.y = symbol.height * i

			@container.addChild symbol

		@container.cache 0, 0, @container.width, @container.height

	startSpin: ()->
		@values = null
		@isSpinning = true
		@isFinalPass = false
		@timeSpinning = 0
		@container.filters = [@blurFilter]


	completeSpin: (opts)->
		@values = opts.values.concat Slots.calculator.spawnValue()
		@timeSpinning = @spinDuration if @timeSpinning > @spinDuration
		@timeSpinning -= @spinDelay * @position

	update: (deltaS)->
		return unless @isSpinning

		@timeSpinning += deltaS

		@isFinalPass = @timeSpinning >= @spinDuration and @values

		deltaPixels = @speed * deltaS

		top = @container.children[0].y - deltaPixels

		if @isFinalPass and @values.length is 0
			if top < 0
				top = 0
				@isSpinning = false
				@container.filters = null
		else
			threshhold = - @container.children[0].height

			if top <= threshhold
				top += @container.children[0].height

				@container.removeChildAt 0
				lastSymbol = _.last @container.children

				if @isFinalPass
					symbol = Slots.symbolBuilder.newSprite @values.shift()
				else
					symbol = Slots.symbolBuilder.newSprite()
				
				symbol.y = lastSymbol.y + lastSymbol.height
				@container.addChild symbol

		for symbol, i in @container.children
			symbol.y = top  + (i * symbol.height)

		@container.updateCache()


class Slots.SymbolBuilder
	config: {}

	constructor: (opts)-> 
		_.extend @config, Slots.config.symbol, opts
		
		@config.image = @config.image or Slots.loader.getResult('symbols')
		
		@config.numSymbols = Math.floor(@config.image.height / @config.height)
		@config.numFramsPerSymbol = Math.floor(@config.image.width / @config.width)

	newSprite: (value = Slots.calculator.spawnValue())->
		firstFrame = value * @config.numFramsPerSymbol
		lastFrame = (value + 1) * @config.numFramsPerSymbol - 1

		sheet = new createjs.SpriteSheet
			images: [@config.image]
			frames:
				width: @config.width
				height: @config.height
				count: @config.numSymbols * @config.numFramsPerSymbol
			animations:
				static: firstFrame
				flash:
					frames: [firstFrame .. lastFrame].concat [lastFrame - 1 .. firstFrame + 1]

		sprite = new createjs.Sprite sheet, 'static'
		sprite.framerate = 30
		sprite.width = @config.width
		sprite.height = @config.height

		sprite


Slots.load()