class @Synth
  constructor: (@ctx) ->

  playNote: (frequency, length) ->
    oscillator = @ctx.createOscillator()
    oscillator.frequency.value = frequency
    oscillator.connect(@ctx.destination)
    oscillator.start(0)
    Meteor.setTimeout ->
      oscillator.stop()
    , length

