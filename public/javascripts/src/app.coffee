Slots = {}

Slots.config = 
	targetFPS: 60
	width: 500
	height: 400
	buttons:
		src: '/images/buttons_sheet.png'
		width: 100
		height: 50
		x: 200
		y: 325
	symbols: 
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
	lines:
		matches: [
			[1, 1, 1, 1, 1]
			[2, 2, 2, 2, 2]
			[0, 0, 0, 0, 0]
			[2, 1, 0, 1, 2]
			[0, 1, 2, 1, 0]
			[1, 2, 2, 2, 1]
			[1, 0, 0, 0, 1]
			[2, 2, 1, 0, 0]
			[0, 0, 1, 2, 2]
		]

Slots.load = ->
	canvas = document.createElement 'canvas'
	canvas.width = @config.width
	canvas.height = @config.height

	document.body.appendChild canvas

	@stage = new createjs.Stage canvas

	@stage.enableMouseOver 10
	
	manifest = [
		{id: 'symbols', src: @config.symbols.src}
		{id: 'buttons', src: @config.buttons.src}
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
	constructor: (opts = {})->
		@payouts = opts.payouts or Slots.config.payouts
		@lines = opts.lines or Slots.config.lines
		
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

	checkWins: (results, opts)->
		results.winnings = 0
		results.flash = []
		results.lines = []

		results.values = [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]

		for line, i in @lines.matches
			break if i >= opts.numLinesBet
			
			lastSymbol = null
			matched = 1
			
			for symbolI, reelI  in line
				if lastSymbol != null
					lastSymbol = results.values[reelI][symbolI]
				else
					matched++ if lastSymbol is results.values[reelI][symbolI]
					lastSymbol = results.values[reelI][symbolI]

			console.log matched

		results

	getSpinResults: (opts)->
		defer = $.Deferred()
		results = {}
		results.values = []

		for i in [0..4]
			for j in [0..2]
				results.values[i] = [] unless results.values[i]
				results.values[i][j] = @spawnValue()

		results = @checkWins results, opts

		setTimeout (-> defer.resolve results), 500

		defer.promise()

class Slots.State
	constructor: ->
		@initReels()
		@initButtons()

	initReels: ->
		@reels = []
		
		for i in [0..4]
			@reels[i] = new Slots.Reel position: i
			Slots.stage.addChild @reels[i].container

		return

	initButtons: ->
		config = Slots.config.buttons
		image = Slots.loader.getResult('buttons')
		
		numFrames = Math.floor(image.width / config.width)

		sheet = new createjs.SpriteSheet
			images: [image]
			frames:
				width: config.width
				height: config.height
				count: numFrames
			animations:
				static: 0
				flash:
					frames: [0 .. numFrames - 1].concat [numFrames - 2 .. 1]

		@spinButton = new createjs.Sprite sheet, 'static'
		@spinButton.framerate = 30
		@spinButton.width = config.width
		@spinButton.height = config.height
		@spinButton.x = config.x
		@spinButton.y = config.y

		@spinButton.addEventListener 'mouseover', -> document.body.style.cursor = 'pointer'
		@spinButton.addEventListener 'mouseout', -> document.body.style.cursor = 'default'

		@spinButton.addEventListener 'click', @spin

		Slots.stage.addChild @spinButton

	spin: =>
		return if @spinningReelCount > 0
		
		@spinningReelCount = 5

		reel.startSpin() for reel in @reels
		
		@spinButton.gotoAndPlay 'flash'
		
		Slots.calculator.getSpinResults(numLinesBet: 9).done @handleSpinResults

	handleSpinResults: (results)=>
		for reel, i in @reels
			reel.completeSpin(values: results.values[i]).done => @completeSpin results

		return

	completeSpin: (results)->
		@spinningReelCount--
		return unless @spinningReelCount is 0

		@spinButton.gotoAndPlay 'static'
		console.log results

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
		@defer = $.Deferred()

		@container.filters = [@blurFilter]


	completeSpin: (opts)->		
		@values = opts.values.concat Slots.calculator.spawnValue()
		@timeSpinning = @spinDuration if @timeSpinning > @spinDuration
		@timeSpinning -= @spinDelay * @position

		@defer.promise()

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
				@defer.resolve()
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
		_.extend @config, Slots.config.symbols, opts
		
		@config.image = @config.image or Slots.loader.getResult('symbols')
		
		@config.numSymbols = Math.floor(@config.image.height / @config.height)
		@config.numFramesPerSymbol = Math.floor(@config.image.width / @config.width)

	newSprite: (value = Slots.calculator.spawnValue())->
		firstFrame = value * @config.numFramesPerSymbol
		lastFrame = (value + 1) * @config.numFramesPerSymbol - 1

		sheet = new createjs.SpriteSheet
			images: [@config.image]
			frames:
				width: @config.width
				height: @config.height
				count: @config.numSymbols * @config.numFramesPerSymbol
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