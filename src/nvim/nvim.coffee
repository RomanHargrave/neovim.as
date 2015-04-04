# nvim.coffee
# communicate with neovim process
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

running_process  = require 'process'
app              = require('remote').require('app')
path             = require 'path'
child_process    = require 'child_process'
Session          = require 'msgpack5rpc'
remote           = require 'remote'
UI               = require './ui'
config           = require './config'
NeoAPI           = require './nvapi'

class NVim
  constructor: ->
    @ui = new UI(config.row, config.col)
    
    # Atom Shell apps are run as 'Atom <path> <args>'
    # might need a better way to locate the arguments
    nvim_args = ['--embed'].concat remote.process.argv[3..]

    # Spawn nvim process
    @nvim_process =
      child_process.spawn('nvim', nvim_args, stdio: ['pipe', 'pipe', process.stderr])

    console.log "nvim instance spawned with pid #{@nvim_process.pid}"

    @nvim_process.on 'close', =>
      console.log 'child process closed'
      @session.detach()
      remote.require('app').quit()

    @session = new Session
    @nvim    = new NeoAPI(@session)

    @session.attach(@nvim_process.stdin, @nvim_process.stdout)

    @session.on 'notification', (method, args) =>
      @ui.handle_redraw args if method == 'redraw'

    @nvim.attach_ui config.col, config.row, true, =>
      @ui.on 'input', (e) => @nvim.input e
      @ui.on 'resize', (col, row) => @nvim.resize_ui col, row

module.exports = NVim
