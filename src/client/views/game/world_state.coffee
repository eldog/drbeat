class @WorldState
  DRAG = 400
  MOVEMENT_FORCE = 200
  JUMP_FORCE = 320
  GRAVITY = 980

  NUMBER_OF_POWS = 100
  POW_DELAY_MS = 100
  POW_SPEED = 500

  constructor: (@game, @config) ->
    AudioContext = window.AudioContext or window.webkitAudioContext
    @audioContext = new AudioContext()
    @synth = new Synth(@audioContext)

  preload: ->
    @game.load.image('player', @config.player)
    @game.load.image('background', @config.background)
    @game.load.image('#', @config.ground)
    @game.load.image('pow', @config.pow)

  createBlock: (sprite, width, x, y) ->
    @groundBlock = @game.add.tileSprite(x * 16, @game.world.height - y * 16,
                                        width * 16 , 16, sprite)
    @game.physics.enable(@groundBlock, Phaser.Physics.ARCADE)
    @groundBlock.body.immovable = true
    @groundBlock.body.allowGravity = false
    @ground.add(@groundBlock)

  create: ->
    @game.stage.backgroundColor = 0x488973

    @game.world.setBounds(0, 0, @config.world.width, @config.world.height)
    @game.add.tileSprite(0, 0, 2000, 2000, 'background')

    @game.physics.startSystem(Phaser.Physics.P2JS)

    @player = @game.add.sprite(16, 16, 'player')

    @ground = @game.add.group()

    createBlock =
    lines = @config.world.map.split('\n')
    maxWidth = 0
    for line, y in lines
      characterCount = 0
      lastCharacter = null
      startX = 0
      if line.length > maxWidth
        maxWidth = line.length
      for character, x in line
        characterCount++
        if (x == line.length - 1 or line[x+1] != character)
          if character != ' '
            @createBlock(character, characterCount, startX, lines.length - y)
          startX = x
          characterCount = 0

    @powPool = @game.add.group()
    for pow in [0..NUMBER_OF_POWS]
      pow = @game.add.sprite(0, 0, 'pow')
      @powPool.add(pow)
      @game.physics.enable(pow, Phaser.Physics.ARCADE)
      pow.body.allowGravity = false
      pow.kill()

    @game.world.setBounds(0, 0, maxWidth * 16, @config.world.height)

    @game.physics.enable(@player, Phaser.Physics.ARCADE)
    @player.body.collideWorldBounds = true

    @game.physics.arcade.gravity.y = GRAVITY
    @player.body.drag.setTo DRAG, 0

    @game.camera.follow(@player)

    @game.input.keyboard.addKeyCapture [
      Phaser.Keyboard.LEFT,
      Phaser.Keyboard.RIGHT,
      Phaser.Keyboard.UP,
      Phaser.Keyboard.DOWN,
      Phaser.Keyboard.SPACEBAR
    ]

    @game.input.gamepad.start()
    @pad1 = @game.input.gamepad.pad1

  shootBullet: ->
    unless @lastBulletShotAt?
      @lastBulletShotAt = 0

    now = @game.time.now
    return if now - @lastBulletShotAt < POW_DELAY_MS

    @lastBulletShotAt = now

    pow = @powPool.getFirstDead()
    return unless pow?
    pow.revive()

    pow.checkWorldBounds = true
    pow.outOfBoundsKill = true

    pow.reset(@player.x, @player.y)

    pow.body.velocity.x = POW_SPEED
    pow.body.velocity.y = 0

    @synth.playNote(440 + @player.body.velocity.y, 200)

  update: ->
    @game.physics.arcade.collide(@player, @ground)
    @_updateCursors()
    if @powIsDown()
      @shootBullet()

  pressingLeft: ->
    @input.keyboard.isDown(Phaser.Keyboard.LEFT) \
      or @pad1.isDown(Phaser.Gamepad.XBOX360_DPAD_LEFT) \
      or @pad1.axis(Phaser.Gamepad.XBOX360_STICK_LEFT_X) < -0.1

  pressingRight: ->
    @input.keyboard.isDown(Phaser.Keyboard.RIGHT) \
      or @pad1.isDown(Phaser.Gamepad.XBOX360_DPAD_RIGHT) \
      or @pad1.axis(Phaser.Gamepad.XBOX360_STICK_LEFT_X) > 0.1

  justPressedJump: (time) ->
    @input.keyboard.justPressed(Phaser.Keyboard.UP, time) \
      or @pad1.justPressed(Phaser.Gamepad.XBOX360_A, time)

  jumpIsDown: ->
    @input.keyboard.isDown(Phaser.Keyboard.UP) \
      or @pad1.isDown(Phaser.Gamepad.XBOX360_A)

  powIsDown: ->
    @input.keyboard.isDown(Phaser.Keyboard.SPACEBAR) \
      or @pad1.isDown(Phaser.Gamepad.XBOX360_RIGHT_TRIGGER)

  _updateCursors: ->
    if @pressingLeft()
      @player.body.velocity.x = -MOVEMENT_FORCE
    if @pressingRight()
      @player.body.velocity.x = MOVEMENT_FORCE

    onTheGround = @player.body.touching.down
    if onTheGround
      @canDoubleJump = onTheGround

    if @justJumped
      @justJumped = false
      @canVariableJump = @canDoubleJump

      console.log @canDoubleJump
      if @canDoubleJump or onTheGround
        @player.body.velocity.y = -JUMP_FORCE
      if not onTheGround
        @canDoubleJump = false

    if @canVariableJump and @game.time.now - @lastJump < 600
      @player.body.velocity.y = -JUMP_FORCE

    if not @jumpIsDown()
      @canVariableJump = false
    else if onTheGround
      @justJumped = true
      @lastJump = @game.time.now

  _updatePointer: ->
    return unless @game.input.pointer1.j

