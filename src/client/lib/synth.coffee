class @Synth
  constructor: (@ctx, type) ->
    @oscillator = @ctx.createOscillator()
    @oscillator.type = type
    @gain = @ctx.createGain()
    @gain.gain.value = 0
    @oscillator.connect(@gain)
    @gain.connect(@ctx.destination)
    @oscillator.start(0)

  playNote: (frequency, length) ->
    if @handle
      Meteor.clearTimeout @handle
    @oscillator.frequency.value = frequency
    @gain.gain.value = 0.5
    @handle = Meteor.setTimeout =>
      @gain.gain.value = 0
    , length

