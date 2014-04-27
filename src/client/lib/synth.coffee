class @Synth
  constructor: (@ctx, @type) ->
    @gain = @ctx.createGain()
    @gain.connect(@ctx.destination)

  playNote: (frequency, length, volume, @endNote) ->
    @oscillator = @ctx.createOscillator()
    @oscillator.type = @type
    @oscillator.frequency.value = frequency
    @oscillator.connect(@gain)
    unless volume?
      volume = 0.5
    @gain.gain.value = volume
    @oscillator.start(0)
    @oscillator.stop(@ctx.currentTime + length / 1000)

