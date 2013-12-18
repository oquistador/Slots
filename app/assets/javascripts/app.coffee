((Slots)->
	"use strict"
	
	Slots.load = ->
		return unless Slots.config

		$canvas = $('canvas')
		$canvas.attr width: Slots.config.width, height: Slots.config.height
		$canvas.on 'mousedown', -> false

		@stage = new createjs.Stage $canvas[0]

		manifest = [
			{id: 'bg', src: Slots.config.background}
			{id: 'symbols', src: Slots.config.symbols.src}
			{id: 'buttons', src: Slots.config.buttons.src}
		]

		@loader = new createjs.LoadQueue false
		@loader.on 'complete', @init
		@loader.loadManifest manifest

	Slots.init = =>
		Slots.user = new Slots.User Slots.config.user
		
		Slots.user.fetch().done ->
			Slots.symbolBuilder = new Slots.SymbolBuilder
			Slots.lineBuilder = new Slots.LineBuilder
			Slots.state = new Slots.State

			createjs.Ticker.timingMod = createjs.Ticker.RAF_SYNCHED
			createjs.Ticker.setFPS Slots.config.targetFPS
			createjs.Ticker.on 'tick', Slots.state.tick

	class Slots.User extends Backbone.Model
		urlRoot: '/api/users'

		spin: (wager)->
			dfr = $.Deferred()

			$.post("#{@url()}/spin", wager).success (results)=>
				@set('credits', results.credits)
				dfr.resolve(results)

			dfr.promise()

	class Slots.State
		constructor: (opts = {})->
			@lines = []
			@totalLines = opts.totalLines or Slots.config.lines.length
			@linesBet = @totalLines
			@bet = 1

			@initBG()
			@initReels()
			@initSpinButton()
			@initFieldButtons()
			@initFieldValues()
			@initReqCredits()

			$(document.body).on 'keypress', (evt)=>
				@spin() if evt.charCode is 32

		initBG: ->
			bg = new createjs.Shape();
			bg.graphics.beginBitmapFill(Slots.loader.getResult("bg")).drawRect(0, 0, Slots.config.width, Slots.config.height)
			Slots.stage.addChild bg

		initReels: ->
			@reels = []
			
			for i in [0..4]
				@reels[i] = new Slots.Reel position: i

			return

		initSpinButton: ->
			config = Slots.config.buttons.spin
			image = Slots.loader.getResult('buttons')
			
			sheet = new createjs.SpriteSheet
				images: [image]
				frames:
					width: config.sheet.width
					height: config.sheet.height
					count: config.sheet.frames
				animations:
					static: 0
					flash:
						frames: [0 .. config.sheet.frames - 1].concat [config.sheet.frames - 2 .. 1]

			@spinButton = new createjs.Sprite sheet, 'static'
			@spinButton.framerate = 30
			@spinButton.width = config.sheet.width
			@spinButton.height = config.sheet.height
			@spinButton.x = config.position.x
			@spinButton.y = config.position.y

			@spinButton.on 'click', @spin

			Slots.stage.addChild @spinButton

		initFieldButtons: ->
			config = Slots.config.buttons.arrows
			image = Slots.loader.getResult('buttons')

			downSheetFrames = []
			for frameCount in [0...config.sheets.down.frames]
				downSheetFrames.push [config.sheets.down.x + (frameCount * config.sheets.down.width), config.sheets.down.y, config.sheets.down.width, config.sheets.down.height, 0]

			upSheetFrames = []
			for frameCount in [0...config.sheets.up.frames]
				upSheetFrames.push [config.sheets.up.x + (frameCount * config.sheets.up.width), config.sheets.up.y, config.sheets.up.width, config.sheets.up.height, 0]

			downSheet = new createjs.SpriteSheet
				images: [image]
				frames: downSheetFrames
				animations:
					default: 0
					clicked: [1, config.sheets.down.frames - 1, 'default', 0.5]

			upSheet = new createjs.SpriteSheet
				images: [image]
				frames: upSheetFrames
				animations:
					default: 0
					clicked: [1, config.sheets.up.frames - 1, 'default', 0.5]

			downSprite = new createjs.Sprite downSheet, 'default'
			downSprite.width = config.sheets.down.width
			downSprite.height = config.sheets.down.height

			upSprite = new createjs.Sprite upSheet, 'default'
			upSprite.width = config.sheets.up.width
			upSprite.height = config.sheets.up.height

			@decreaseLinesButton = downSprite.clone()
			_.extend @decreaseLinesButton, {x: config.positions.decreaseLines.x, y: config.positions.decreaseLines.y}
			@decreaseLinesButton.addEventListener 'click', (evt)=>
				evt.target.gotoAndPlay 'clicked'
				@decrementLines()

			@decreaseBetButton = downSprite.clone()
			_.extend @decreaseBetButton, {x: config.positions.decreaseBet.x, y: config.positions.decreaseBet.y}
			@decreaseBetButton.addEventListener 'click', (evt)=>
				evt.target.gotoAndPlay 'clicked'
				@decrementBet()

			@increaseLinesButton = upSprite.clone()
			_.extend @increaseLinesButton, {x: config.positions.increaseLines.x, y: config.positions.increaseLines.y}
			@increaseLinesButton.addEventListener 'click', (evt)=>
				evt.target.gotoAndPlay 'clicked'
				@incrementLines()

			@increaseBetButton = upSprite.clone()
			_.extend @increaseBetButton, {x: config.positions.increaseBet.x, y: config.positions.increaseBet.y}
			@increaseBetButton.addEventListener 'click', (evt)=>
				evt.target.gotoAndPlay 'clicked'
				@incrementBet()

			Slots.stage.addChild @decreaseLinesButton
			Slots.stage.addChild @decreaseBetButton
			Slots.stage.addChild @increaseLinesButton
			Slots.stage.addChild @increaseBetButton

		initFieldValues: ->
			config = Slots.config.fields
			attrs = 
				textAlign: 'center'
				textBaseline: 'middle'

			@linesField = new createjs.Text @linesBet, config.lines.font, config.lines.color
			_.extend @linesField, attrs, {x: config.lines.x, y: config.lines.y}		

			@betField = new createjs.Text @bet, config.bet.font, config.bet.color
			_.extend @betField, attrs, {x: config.bet.x, y: config.bet.y}

			@totalBetField = new createjs.Text @linesBet * @bet, config.lines.font, config.totalBet.color
			_.extend @totalBetField, attrs, {x: config.totalBet.x, y: config.totalBet.y}

			@winField = new createjs.Text 0, config.win.font, config.win.color
			_.extend @winField, attrs, {x: config.win.x, y: config.win.y}

			@balanceField = new createjs.Text Slots.user.get('credits'), config.balance.font, config.balance.color
			_.extend @balanceField, attrs, {x: config.balance.x, y: config.balance.y}
			
			Slots.stage.addChild @linesField
			Slots.stage.addChild @betField
			Slots.stage.addChild @totalBetField
			Slots.stage.addChild @winField
			Slots.stage.addChild @balanceField

		initReqCredits: ->
			$('#request-credits').on 'click', (ev)=>
				ev.preventDefault()
				@updateCredits 100, true


		incrementLines: ->
			return if @spinningReelCount > 0
			@linesBet++ if @linesBet < @totalLines
			@linesField.text = @linesBet
			@totalBetField.text = @linesBet * @bet
			Slots.stage.update()

		decrementLines: ->
			return if @spinningReelCount > 0
			@linesBet-- if @linesBet > 1
			@linesField.text = @linesBet
			@totalBetField.text = @linesBet * @bet
			Slots.stage.update()

		incrementBet: ->
			return if @spinningReelCount > 0
			@bet++
			@betField.text = @bet
			@totalBetField.text = @linesBet * @bet
			Slots.stage.update()

		decrementBet: ->
			return if @spinningReelCount > 0
			@bet-- if @bet > 1
			@betField.text = @bet
			@totalBetField.text = @linesBet * @bet
			Slots.stage.update()

		updateWin: (win)->
			@winField.text = win
			Slots.stage.update()

		updateCredits: (addCredits = 0, save)->
			credits = Slots.user.get('credits') + addCredits
			Slots.user.set('credits', credits).save() if save
			
			@balanceField.text = credits
			Slots.stage.update()

		spin: =>
			return if @spinningReelCount > 0

			while Slots.user.get('credits') < @linesBet * @bet
				if @bet > 1
					@decrementBet()
				else if @linesBet > 1
					@decrementLines()
				else
					return @openInsufficientCreditsDialog()

			for line in @lines
				Slots.stage.removeChild line
			
			@spinningReelCount = 5

			reel.startSpin() for reel in @reels
			
			@spinButton.gotoAndPlay 'flash'
			
			@updateWin 0
			@updateCredits(- @linesBet * @bet)
			
			Slots.user.spin(lines: @linesBet, bet: @bet).done @handleSpinResults

		openInsufficientCreditsDialog: ->
			alert "You're done."

		handleSpinResults: (results)=>
			for reel, i in @reels
				reel.completeSpin(values: results.values[i]).done => @completeSpin results

			return

		completeSpin: (results)->
			@spinningReelCount--
			return unless @spinningReelCount is 0

			@spinButton.gotoAndPlay 'static'
			
			if results.wins.length > 0
				@lines = []
				flash = {}

				for win in results.wins
					for match in win.matches
						flash[match.position[0]] = {} unless flash[match.position[0]]
						flash[match.position[0]][match.position[1]] = 1

					line = Slots.lineBuilder.newLine win.line
					@lines.push line
					
					Slots.stage.addChild line

				for reelI, symbols of flash
					@reels[reelI].flash symbols
			
			@updateWin results.reward
			@updateCredits()

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

			mask = new createjs.Shape
			mask.x = @container.x
			mask.y = @container.y
			mask.graphics.drawRect 0, 0, @container.width, @container.height

			@container.mask = mask

			for i in [0..3]
				symbol = Slots.symbolBuilder.newSprite()
				symbol.y = symbol.height * i

				@container.addChild symbol

			@render()

		render: ->
			Slots.stage.addChild @container

		flash: (symbols)->
			@container.getChildAt(symbolI).gotoAndPlay('flash') for symbolI of symbols
			return

		startSpin: ->
			@values = null
			@isSpinning = true
			@isFinalPass = false
			@timeSpinning = 0
			@defer = $.Deferred()

		completeSpin: (opts)->		
			@values = opts.values.concat Math.floor(Math.random() * @numSymbols)
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

			return

	class Slots.LineBuilder
		constructor: (opts = {})->
			@graphics = []
			
			regX = opts.regX or Slots.config.reel.regX
			regY = opts.regX or Slots.config.reel.regY
			width = opts.width or Slots.config.reel.width * 5
			symbolWidth = opts.symbolWidth or Slots.config.symbols.width
			symbolHeight = opts.symbolHeight or Slots.config.symbols.height
			lines = opts.lines or Slots.config.lines

			for line, i in lines
				graphic = new createjs.Graphics
				graphic.setStrokeStyle(5).beginStroke "hsl(#{i * 360 / lines.length}, 80%, 50%)"
				
				graphic.moveTo 0 + regX, line[0] * symbolHeight + 50 + regY
				
				for y, x in line
					x = x * symbolWidth + 50 + regX
					y = y * symbolHeight + 50 + regY
					
					graphic.lineTo x, y

				graphic.lineTo width, y
				
				@graphics.push graphic

		newLine: (ord)->
			new createjs.Shape @graphics[ord]

	class Slots.SymbolBuilder
		constructor: (opts)-> 
			config = {}
			_.extend config, Slots.config.symbols, opts
			
			@image = config.image or Slots.loader.getResult('symbols')
			@width = config.width
			@height = config.height
			
			@numSymbols = Math.floor(@image.height / @height)
			@numFramesPerSymbol = Math.floor(@image.width / @width)

		newSprite: (value)->
			value ?= Math.floor(Math.random() * @numSymbols)

			firstFrame = value * @numFramesPerSymbol
			lastFrame = (value + 1) * @numFramesPerSymbol - 1

			sheet = new createjs.SpriteSheet
				images: [@image]
				frames:
					width: @width
					height: @height
					count: @numSymbols * @numFramesPerSymbol
				animations:
					static: firstFrame
					flash:
						frames: [firstFrame .. lastFrame].concat [lastFrame - 1 .. firstFrame + 1]

			sprite = new createjs.Sprite sheet, 'static'
			sprite.framerate = 30
			sprite.width = @width
			sprite.height = @height

			sprite

	$(Slots.load())
)(window.Slots or {})