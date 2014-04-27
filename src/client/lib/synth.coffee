class @Synth
  constructor: (@ctx, type) ->
    @oscillator = @ctx.createOscillator()
    @oscillator.type = type
    @gain = @ctx.createGain()
    @gain.gain.value = 0
    @oscillator.connect(@gain)
    @gain.connect(@ctx.destination)
    @oscillator.start(0)

  playNote: (frequency, length, volume, @endNote) ->
    if @handle
      Meteor.clearTimeout @handle
    @oscillator.frequency.value = frequency
    unless volume?
      volume = 0.5
    @gain.gain.value = volume
    @length = length
    if @endNote?
      @length /= 2
    @handle = Meteor.setTimeout =>
      if @endNote
        @endNote = null
        @oscillator.frequency.value = frequency
        @handle = Meteor.setTimeout =>
          @gain.gain.value = 0
        , @length
      else
        @gain.gain.value = 0
    , @length

