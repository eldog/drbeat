WORLD = '''

                         B B
                        ###########


              B    B
          ############

                                                      ##########


                                      #####


                                                            #####





                        #######



            ####                                                      BB

                            B                                   ##########
                            ##
                                                  #####

      ###

                  ###



  ##############################################################################
'''

Template.game.rendered = ->
  config =
    background: 'background.png'
    player: 'player0.png'
    pow: 'pow.png'
    ground: 'ground.png'
    badguy: 'badguy.png'
    badPow: 'bad-pow.png'
    world:
      map: WORLD
      width: 2048
      height: 1024
  game = new Phaser.Game(800, 600, Phaser.AUTO, 'game')
  game.state.add('world', new WorldState(game, config), true)

