class @Noise
  BUFFER_SIZE = 4096

  constructor: (@ctx, multiplier) ->
    lastOut = 0.0
    bufferSize = 2 * @ctx.sampleRate
    @noiseBuffer = @ctx.createBuffer(1, bufferSize, @ctx.sampleRate)
    output = @noiseBuffer.getChannelData(0)
    unless multiplier?
      multiplier = 3.5
    for i in [0...bufferSize]
      white = Math.random() * 2 - 1
      output[i] = (lastOut + (0.02 * white)) / 1.02
      lastOut = output[i]
      output[i] *= multiplier

  playNote: (length) ->
    @node = @ctx.createBufferSource()
    @node.buffer = @noiseBuffer
    @node.loop = true
    @node.start 0
    @node.stop @ctx.currentTime + length / 1000
    @node.connect @ctx.destination

