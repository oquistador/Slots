Slots = {}

Slots.config = 
	targetFPS: 60
	width: 500
	height: 400
	symbol: 
		src: 'symbols_sheet.png'
		width: 100
		height: 100
		probabilities: [
			0,
			1, 1,
			2, 2, 2,
			3, 3, 3, 3,
			4, 4, 4, 4, 4,
			5, 5, 5, 5, 5, 5,
			6, 6, 6, 6, 6, 6, 6,
			7, 7, 7, 7, 7, 7, 7, 7,
			8, 8, 8, 8
			9
		]
	reel:
		width: 100
		height: 300
		regX: 0
		regY: 0
		spinDuration: 0.4
		spinDelay: 0.5
		speed: 2000

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
	Slots.symbolBuilder = new Slots.SymbolBuilder
	Slots.state = new Slots.State

	createjs.Ticker.timingMod = createjs.Ticker.RAF_SYNCHED
	createjs.Ticker.setFPS Slots.config.targetFPS
	createjs.Ticker.addEventListener 'tick', Slots.state.tick

class Slots.State
	constructor: ->
		@reels = []
		
		for i in [0..4]
			@reels[i] = new Slots.Reel position: i
			Slots.stage.addChild @reels[i].container
			@reels[i].spin values: [0, 0, 0]

	tick: (evt)=>
		deltaS = evt.delta / 1000
		@reels.forEach (reel)-> reel.update deltaS

		Slots.stage.update evt
		return

class Slots.Reel
	config: {}
	isSpinning: false

	constructor: (opts)->
		_.extend @config, Slots.config.reel, opts

		@container = new createjs.Container
		@container.y = @config.regY
		@container.x = @config.position * @config.width + @config.regX

		for i in [0..3]
			symbol = Slots.symbolBuilder.newSprite()
			symbol.y = symbol.height * i

			@container.addChild symbol

	spin: (opts)->
		@values = opts.values.concat Slots.symbolBuilder.spawnValue()
		@isSpinning = true
		@isFinalPass = false
		@timeSpinning = - @config.position * @config.spinDelay

	update: (deltaS)->
		return unless @isSpinning

		@timeSpinning += deltaS

		@isFinalPass = @timeSpinning >= @config.spinDuration

		deltaPixels = @config.speed * deltaS

		top = @container.children[0].y - deltaPixels

		if @isFinalPass and @values.length is 0
			if top < 0
				top = 0
				@isSpinning = false

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

		return


class Slots.SymbolBuilder
	config: {}

	constructor: (opts)-> 
		_.extend @config, Slots.config.symbol, opts
		
		@config.image = @config.image or Slots.loader.getResult('symbols')
		
		@config.numSymbols = Math.floor(@config.image.height / @config.height)
		@config.numFramsPerSymbol = Math.floor(@config.image.width / @config.width)

	spawnValue: ->
		 _.shuffle(_.clone(@config.probabilities))[0]

	newSprite: (value = @spawnValue())->
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