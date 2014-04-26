class @Noise
  BUFFER_SIZE = 4096

  constructor: (@ctx) ->
    @lastOut = 0.0
    @node = @ctx.createScriptProcessor(BUFFER_SIZE, 1, 1)
    @node.onaudioprocess = (e) =>
      output = e.outputBuffer.getChannelData(0)
      for i in [0...BUFFER_SIZE]
        white = Math.random() * 2 - 1
        output[i] = (@lastOut + (0.02 * white)) / 1.02
        @lastOut = output[i]
        output[i] *= 3.5
    @gain = @ctx.createGain()
    @gain.gain.value = 0
    @node.connect(@gain)
    @gain.connect(@ctx.destination)

  playNote: (length) ->
    if @handle
      Meteor.clearTimeout @handle
    @gain.gain.value = 0.5
    @handle = Meteor.setTimeout =>
      @gain.gain.value = 0
    , length


