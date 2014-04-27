class @WorldState
  SEQUENCE = [
    [0, 3,  3, 0,  3, 3,  3, 0]
    [0, 0,  2, 0,  0, 0,  2, 0]
    [1, 0,  0, 0,  1, 0,  0, 1]
    [4, 0,  0, 0,  0, 0,  0, 0]
    [0, 0,  0, 0,  5, 5,  0, 0]
  ]

  TEXT =
    1: 'Use the arrow keys or plug in an xbox controller on chrome to play'
    2: 'Welcome to Dr. Beat.'
    d: [
      'Still searching for that perfect beat?'
      'Why do you carry a pager?'
      'Where do you get all your underground hits from?'
    ]

  BPM = 120 * SEQUENCE[0].length / 4

  KICK_PITCH = 110
  HIGH_HAT_PITCH = 880

  ENCOUNTER_DISTANCE = 100


  DRAG = 400
  MOVEMENT_FORCE = 200
  JUMP_FORCE = 320
  GRAVITY = 980

  NUMBER_OF_POWS = 100
  POW_DELAY_MS = 300
  POW_SPEED = 500

  BADGUY__DELAY_MS = 100
  BADGUY_POW_SPEED = POW_SPEED / 2

  MAX_SPEED_X = 250
  MAX_SPEED_Y = MAX_SPEED_X * 10

  SCHEDULE_AHEAD_SECS = 1

  SOUND_DISTANCE = 800

  constructor: (@game, @config) ->
    AudioContext = window.AudioContext or window.webkitAudioContext
    @audioContext = new AudioContext()
    @synth = new Synth(@audioContext, 'sawtooth')
    @beatSynth = new Synth(@audioContext, 'sine')
    @highHatSynth = new Synth(@audioContext, 'sine')
    @noiseSynth = new Noise(@audioContext)
    @sequence = SEQUENCE
    @sequenceIndex = 0
    @text = TEXT

  preload: ->
    @game.load.spritesheet('player', @config.player, 16, 16, 3)
    @game.load.image('background', @config.background)
    @game.load.image('#', @config.ground)
    @game.load.image('pow', @config.pow)
    @game.load.image('badguy', @config.badguy)
    @game.load.image('bad-pow', @config.badPow)
    @game.load.image('badguy2', @config.badguy2)
    @game.load.image('bad-pow2', @config.badPow2)
    @game.load.image('-', @config.paving)
    @game.load.image('sky', 'sky.png')
    @game.load.image('d', 'dude.png')
    @game.load.image('%', 'solid-ground.png')

  createBlock: (sprite, width, x, y) ->
    groundBlock = @game.add.tileSprite(x * 16, @game.world.height - y * 16,
                                        width * 16 , 16, sprite)
    @game.physics.enable(groundBlock, Phaser.Physics.ARCADE)
    groundBlock.body.immovable = true
    groundBlock.body.allowGravity = false
    @ground.add(groundBlock)

  createPassableBlock: (sprite, width, x, y) ->
    groundBlock = @game.add.tileSprite(x * 16, @game.world.height - y * 16,
                                        width * 16 , 16, sprite)

  createTextEncounter: (sprite, width, x, y) ->
    x *= 16
    y = @game.world.height - y * 16
    encounter = @game.add.tileSprite(x, y, width * 16 , 16, sprite)
    texts = @text[sprite]
    encounterTexts = []
    for text in texts
      t = @game.add.text(x, y - 32, text,
        {font: "16px monospace", fill: "#000000", align: "center"}
      )
      t.visible = false
      encounterTexts.push t
    encounter.nextTextIndex = 0
    encounter.texts = encounterTexts
    encounter.nextText = ->
      encounter.text = encounter.texts[encounter.nextTextIndex++ % encounter.texts.length]
    encounter.nextText()
    @encounters.add(encounter)

  createText: (x, y, key) ->
    @game.add.text(x * 16, @game.world.height - y * 16, @text[key],
      {font: "16px monospace", fill: "#ffffff", align: "center"}
    )


  createBadguy: (x, y, sprite, group, baseFrequency, powSpeedY) ->
    x = x * 16
    y = @game.world.height - y * 16
    badguy = @game.add.sprite(x, y, sprite)
    badguy.baseFrequency = baseFrequency
    badguy.startingX = x
    badguy.startingY = y
    badguy.powSpeedY = powSpeedY
    @game.physics.enable(badguy, Phaser.Physics.ARCADE)
    badguy.synth = new Synth(@audioContext, 'sine')
    badguy.body.collideWorldBounds = true
    badguy.body.mass = 1
    badguy.body.drag.setTo(10000, 0)
    group.add(badguy)

  reset: ->
    #for badguyGroup in @badguyGroups
    #  badguyGroup.forEach (badguy) ->
    #    badguy.revive()
    #    badguy.x = badguy.startingX
    #    badguy.y = badguy.startingY
    @player.x = @playerStartX
    @player.y = @playerStartY
    @player.animations.play('right')

  badGuyShoot: (badguy, powPool) ->
    unless badguy.lastBulletShotAt?
      badguy.lastBulletShotAt = 0

    now = @game.time.now
    return if now - badguy.lastBulletShotAt < BADGUY__DELAY_MS

    badguy.lastBulletShotAt = now

    pow = powPool.getFirstDead()
    return unless pow?
          encounter.nextText()
    pow.revive()

    pow.checkWorldBounds = true
    pow.outOfBoundsKill = true

    pow.reset(badguy.x, badguy.y)

    if badguy.x - @player.x > 0
      powSpeed = BADGUY_POW_SPEED * -1
    else
      powSpeed = BADGUY_POW_SPEED
    pow.body.velocity.x = powSpeed
    pow.body.velocity.y = badguy.powSpeedY
    distance = @player.world.distance(pow.world)
    if distance < SOUND_DISTANCE
      volume = (1 - (distance / SOUND_DISTANCE)) * 0.5
      badguy.synth.playNote(badguy.y / @config.world.height * 440,
                          BADGUY__DELAY_MS * 2, volume)

  create: ->
    maxWidth = 0
    lines = @config.world.map.split('\n')
    backgroundLines = 0
    backgrounds = []
    for line, i in lines
      if line.indexOf('!') > -1
        backgroundName = line[2..].trim()
        backgrounds.push [backgroundName, i - backgroundLines]
        backgroundLines++
      else if line.length > maxWidth
        maxWidth = line.length

    @game.stage.disableVisibilityChange = true
    @game.stage.backgroundColor = 0x488973

    width = maxWidth * 16
    numberOfLines = lines.length - backgroundLines
    height = numberOfLines * 16
    @game.world.setBounds(0, 0, width, height)
    @maxDistance = Math.sqrt(Math.pow(height, 2) + Math.pow(width, 2))
    for [background, i], j in backgrounds
      next = backgrounds[j+1]
      y = i * 16
      if next?
        backgroundHeight = next[1] * 16 - y
      else
        backgroundHeight = height - y
      @game.add.tileSprite(0, y, width, backgroundHeight, background)

    @game.physics.startSystem(Phaser.Physics.P2JS)

    @ground = @game.add.group()
    @badguys = @game.add.group()
    @badguys2 = @game.add.group()
    @encounters = @game.add.group()

    @badguyGroups = [@badguys, @badguys2]

    @badguyPowPool = @game.add.group()
    @badguyPowPool.spriteName = 'bad-pow'
    @badguyPowPool.allowGravity = true
    @badguyPowPool2 = @game.add.group()
    @badguyPowPool2.spriteName = 'bad-pow2'
    @badguyPowPool2.allowGravity = false

    @badguyPowPools = [@badguyPowPool, @badguyPowPool2]

    lines = @config.world.map.split('\n')
    backgroundLines = 0
    for line, y in lines
      characterCount = 0
      positionY = numberOfLines - (y - backgroundLines)
      lastCharacter = null
      startX = 0
      if line.indexOf('!') > -1
        # BACKGROUND LINE - IGNORE
        backgroundLines++
        continue
      for character, x in line
        if (x == line.length - 1 or line[x+1] != character)
          if character in ['#', '-', '%']
            @createBlock(character, characterCount, startX, positionY)
          if character in ['d']
            @createTextEncounter('d', characterCount, startX, positionY)
          startX = x
          characterCount = 1
          if character == 'B'
            @createBadguy(x, positionY, 'badguy', @badguys, 880, -200)
          if character == 'C'
            @createBadguy(x, positionY, 'badguy2', @badguys2, 880 * 2, 0)
          if character in ['1', '2']
            @createText(x, positionY, character)
          if character == 'S'
            @playerStartX = x * 16
            @playerStartY = @game.world.height - positionY * 16
        else
          characterCount++

    @player = @game.add.sprite(@playerStartX, @playerStartY, 'player')
    @player.animations.add('left', [0], 1, true)
    @player.animations.add('right', [1], 1, true)
    @player.animations.add('dead', [2], 1, true)
    @player.animations.play('right')
    @player.health = 1

    @powPool = @game.add.group()
    for pow in [0..NUMBER_OF_POWS]
      pow = @game.add.sprite(0, 0, 'pow')
      @powPool.add(pow)
      @game.physics.enable(pow, Phaser.Physics.ARCADE)
      pow.kill()

    for badguyPowPool in @badguyPowPools
      for pow in [0..NUMBER_OF_POWS]
        pow = @game.add.sprite(0, 0, badguyPowPool.spriteName)
        badguyPowPool.add(pow)
        @game.physics.enable(pow, Phaser.Physics.ARCADE)
        pow.body.allowGravity = badguyPowPool.allowGravity
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

    @winnerText = @game.add.text(0, 0,
      'Well done. You beat the game',
      font: "32px monospace", fill: "#ffffff", align: "center")

    @winnerText.fixedToCamera = true

    @winnerText.cameraOffset.setTo(200, 500)
    @winnerText.visible = false



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
    pow.body.velocity.y = -POW_SPEED / 2
    @synth.playNote(440 + 2000 * (@player.body.velocity.y / MAX_SPEED_Y),
                    POW_DELAY_MS / 2)

  update: ->
    @game.physics.arcade.collide(@player, @ground)

    @encounters.forEach (encounter) =>
      distance = @player.x - encounter.x
      inDistance = distance < ENCOUNTER_DISTANCE
      if inDistance
        encounter.text.visible = true
      else
        if encounter.text.visible?
          encounter.text.visible = false
          encounter.nextText()
        else
          encounter.text.visible = false

    allBadGuysDead = true
    for badguyGroup in @badguyGroups
      badguyGroup.forEachAlive (badguy) ->
        allBadGuysDead = false
      @game.physics.arcade.collide(badguyGroup, @ground)
      @game.physics.arcade.collide(badguyGroup, @player)
      @game.physics.arcade.collide @powPool, badguyGroup, (pow, badGuy) ->
        pow.kill()
        badGuy.kill()
    @game.physics.arcade.collide @powPool, @ground, (pow, ground) ->
      pow.kill()

    @winnerText.visible = allBadGuysDead

    for badguyPowPool in @badguyPowPools
      @game.physics.arcade.collide badguyPowPool, @player, (player, badPow) ->
        player.health = 0
        player.body.velocity.x = 0
        player.animations.play('dead')
        badPow.kill()

      @game.physics.arcade.collide badguyPowPool, @ground, (badPow, ground) ->
        badPow.kill()

      @game.physics.arcade.collide @powPool, badguyPowPool, (pow, badPow) ->
        pow.kill()
        badPow.kill()

    if @player.health > 0
      @_updateCursors()
    if @powIsDown() and @player.health > 0
      @shootBullet()
    if @reviveIsDown()
      @player.revive()
      @reset()
    now = @audioContext.currentTime
    if @last?
      diff = now - @last
      threshold = 60 / BPM
      if diff > threshold

        for track, i in @sequence
          instrument = track[@sequenceIndex]
          if instrument > 0
            noteLength = (threshold / 4) * 1000
            switch instrument
              when 1
                @beatSynth.playNote(@player.x * KICK_PITCH / @game.world.width, noteLength)
              when 2
                @noiseSynth.playNote(noteLength)
              when 3
                @highHatSynth.playNote(@player.y * HIGH_HAT_PITCH / @game.world.height, noteLength)
              when 4
                @badguys.forEachAlive (badGuy) =>
                  @badGuyShoot(badGuy, @badguyPowPool)
              when 5
                @badguys2.forEachAlive (badGuy) =>
                  @badGuyShoot(badGuy, @badguyPowPool2)

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
      @player.animations.play('left')
      @facing = 'left'
    if @pressingRight()
      @player.body.velocity.x = MOVEMENT_FORCE
      @player.animations.play('right')
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

