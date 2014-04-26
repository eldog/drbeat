class @WorldState
  SEQUENCE = [
    [0, 3,  3, 0,  3, 3,  3, 0]
    [0, 0,  2, 0,  0, 0,  2, 0]
    [1, 0,  0, 0,  1, 0,  0, 1]
  ]

  BPM = 120 * SEQUENCE[0].length / 4

  KICK_PITCH = 110
  HIGH_HAT_PITCH = 220

  DRAG = 400
  MOVEMENT_FORCE = 200
  JUMP_FORCE = 320
  GRAVITY = 980

  NUMBER_OF_POWS = 100
  POW_DELAY_MS = 100
  POW_SPEED = 500

  BADGUY__DELAY_MS = 1000
  BADGUY_POW_SPEED = POW_SPEED / 2

  MAX_SPEED_X = 250
  MAX_SPEED_Y = MAX_SPEED_X * 10

  SCHEDULE_AHEAD_SECS = 1

  constructor: (@game, @config) ->
    AudioContext = window.AudioContext or window.webkitAudioContext
    @audioContext = new AudioContext()
    @synth = new Synth(@audioContext, 'sawtooth')
    @beatSynth = new Synth(@audioContext, 'sine')
    @highHatSynth = new Synth(@audioContext, 'sine')
    @noiseSynth = new Noise(@audioContext)
    @sequence = SEQUENCE
    @sequenceIndex = 0

  preload: ->
    @game.load.image('player', @config.player)
    @game.load.image('background', @config.background)
    @game.load.image('#', @config.ground)
    @game.load.image('pow', @config.pow)
    @game.load.image('badguy', @config.badguy)
    @game.load.image('bad-pow', @config.badPow)

  createBlock: (sprite, width, x, y) ->
    groundBlock = @game.add.tileSprite(x * 16, @game.world.height - y * 16,
                                        width * 16 , 16, sprite)
    @game.physics.enable(groundBlock, Phaser.Physics.ARCADE)
    groundBlock.body.immovable = true
    groundBlock.body.allowGravity = false
    @ground.add(groundBlock)

  createBadguy: (x, y) ->
    x = x * 16
    y = y * 16
    console.log x, y
    badguy = @game.add.sprite(x, y, 'badguy')
    badguy.startingX = x
    badguy.startingY = y
    @game.physics.enable(badguy, Phaser.Physics.ARCADE)
    badguy.synth = new Synth(@audioContext, 'sine')
    badguy.body.collideWorldBounds = true
    badguy.body.mass = 1
    badguy.body.drag.setTo(10000, 0)
    @badguys.add(badguy)

  reset: ->
    @badguys.forEach (badguy) ->
      badguy.revive()
      badguy.x = badguy.startingX
      badguy.y = badguy.startingY
    @player.x = 16
    @player.y = 16

  badGuyShoot: (badguy) ->
    unless badguy.lastBulletShotAt?
      badguy.lastBulletShotAt = 0

    now = @game.time.now
    return if now - badguy.lastBulletShotAt < BADGUY__DELAY_MS

    badguy.lastBulletShotAt = now

    pow = @badguyPowPool.getFirstDead()
    return unless pow?
    pow.revive()

    pow.checkWorldBounds = true
    pow.outOfBoundsKill = true

    pow.reset(badguy.x, badguy.y)

    if badguy.x - @player.x > 0
      powSpeed = BADGUY_POW_SPEED * -1
    else
      powSpeed = BADGUY_POW_SPEED
    pow.body.velocity.x = powSpeed
    pow.body.velocity.y = 0
    badguy.synth.playNote(badguy.y / @config.world.height * 440, BADGUY__DELAY_MS / 2)

  create: ->
    maxWidth = 0
    lines = @config.world.map.split('\n')
    for line in lines
      if line.length > maxWidth
        maxWidth = line.length

    @game.stage.disableVisibilityChange = true
    @game.stage.backgroundColor = 0x488973

    @game.world.setBounds(0, 0, maxWidth * 16, @config.world.height)
    @game.add.tileSprite(0, 0, 2000, 2000, 'background')

    @game.physics.startSystem(Phaser.Physics.P2JS)

    @player = @game.add.sprite(16, 16, 'player')

    @ground = @game.add.group()
    @badguys = @game.add.group()

    @badguyPowPool = @game.add.group()

    lines = @config.world.map.split('\n')
    for line, y in lines
      characterCount = 0
      lastCharacter = null
      startX = 0
      for character, x in line
        characterCount++
        if (x == line.length - 1 or line[x+1] != character)
          if character == '#'
            @createBlock(character, characterCount, startX, lines.length - y)
          startX = x
          characterCount = 0
          if character == 'B'
            @createBadguy(x, 0)

    @powPool = @game.add.group()
    for pow in [0..NUMBER_OF_POWS]
      pow = @game.add.sprite(0, 0, 'pow')
      @powPool.add(pow)
      @game.physics.enable(pow, Phaser.Physics.ARCADE)
      pow.body.allowGravity = false
      pow.kill()

    for pow in [0..NUMBER_OF_POWS]
      pow = @game.add.sprite(0, 0, 'bad-pow')
      @badguyPowPool.add(pow)
      @game.physics.enable(pow, Phaser.Physics.ARCADE)
      pow.body.allowGravity = false
      pow.kill()

    @game.physics.enable(@player, Phaser.Physics.ARCADE)
    @player.body.collideWorldBounds = true

    @game.physics.arcade.gravity.y = GRAVITY
    @player.body.drag.setTo DRAG, 0
    @player.body.maxVelocity.setTo(MAX_SPEED_X, MAX_SPEED_Y)

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

    if @facing == 'left'
      powSpeed = POW_SPEED * -1
    else
      powSpeed = POW_SPEED
    pow.body.velocity.x = powSpeed
    pow.body.velocity.y = 0
    @synth.playNote(440 + 2000 * (@player.body.velocity.y / MAX_SPEED_Y),
                    POW_DELAY_MS / 2)

  update: ->
    @game.physics.arcade.collide(@player, @ground)
    @game.physics.arcade.collide(@badguys, @ground)
    @game.physics.arcade.collide(@badguys, @player)
    @game.physics.arcade.collide @powPool, @badguys, (pow, badGuy) ->
      pow.kill()
      badGuy.kill()
    @game.physics.arcade.collide @powPool, @ground, (pow, ground) ->
      pow.kill()

    @game.physics.arcade.collide @badguyPowPool, @player, (player, badPow) ->
      player.kill()
      badPow.kill()

    @game.physics.arcade.collide @badguyPowPool, @ground, (badPow, ground) ->
      badPow.kill()

    @_updateCursors()
    if @powIsDown()
      @shootBullet()
    if @reviveIsDown()
      @player.revive()
      @reset()
    now = @audioContext.currentTime
    if @last?
      diff = now - @last
      threshold = 60 / BPM
      if diff > threshold
        @badguys.forEachAlive (badGuy) =>
          @badGuyShoot(badGuy)
        for track, i in @sequence
          instrument = track[@sequenceIndex]
          if instrument > 0
            noteLength = (threshold / 4) * 1000
            if instrument == 1
              @beatSynth.playNote(@player.x * KICK_PITCH / @game.world.width, noteLength)
            if instrument == 2
              @noiseSynth.playNote(noteLength)
            if instrument == 3
              @highHatSynth.playNote(@player.y * HIGH_HAT_PITCH / @game.world.height, noteLength)
        @sequenceIndex = (@sequenceIndex + 1) % @sequence[0].length
        @last = now
    else
      @beatSynth.playNote(110, 60 / BPM * 1000)
      @last = now

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

  reviveIsDown: ->
    @input.keyboard.isDown(Phaser.Keyboard.ENTER) \
      or @pad1.isDown(Phaser.Gamepad.XBOX360_Y)

  _updateCursors: ->
    if @pressingLeft()
      @player.body.velocity.x = -MOVEMENT_FORCE
      @facing = 'left'
    if @pressingRight()
      @player.body.velocity.x = MOVEMENT_FORCE
      @facing = 'right'

    onTheGround = @player.body.touching.down
    if onTheGround
      @canDoubleJump = onTheGround

    if @justJumped
      @justJumped = false
      @canVariableJump = @canDoubleJump

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

