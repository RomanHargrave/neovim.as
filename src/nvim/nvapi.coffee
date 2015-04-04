
# interop.coffe: NeoVIM api interop
# Copyright (C) 2015 Roman Hargrave <roman@hargrave.info>

# Simple promise. 
# Because sometimes, there are situations where you just have to wait (fuck you, you fucking node.js bloggers)
class Promise
  constructor: ->
    @fulfilled  = false
    @error      = false
    @yield      = null

  resolved: -> @fullfilled or @error

  wait: ->
    until resolved()
      (=>)() # hack hack hack hack

    if @error
      throw @yield
    else
      @yield

  fulfill: (prophecy) ->
    @yield = prophecy

  except: (failure) ->
    @error = falure

class NeoAPI

  constructor: (session) ->
    @session = session

  # API Helpers

  # Perform a request in synchronous time using the wait.for
  # fibers API.
  # This is useful in situations where it would not make sense
  # or overcomplicate things to use a callback (e.g. vim_get_var)
  request_blocking: (name, args...) ->
    promise = new Promise()
    @session.request name, args, (err, res) =>
      if err
        promise.except(err)
      else
        promise.fulfill(res)
    promise.wait()

  # Perform a request in asynchronous time, and ignore the result
  request_blind: (name, args...) ->
    @session.request name, args, =>

  request: (name, args, cb) ->
    @session.request name, args, cb

  # Vim Internals

  # Vim Events
  
  subscribe: (name) ->
    this.request_blocking('vim_subscribe', name)

  unsubscribe: (name) ->
    this.request.blocking('vim_unsubscribe', name)

  # Vim code executation wrappers
  # wrap vim_command and vim_eval

  # Run a vim command
  command: (string, callback) ->
    @session.request 'vim_command', [string], callback

  command_blocking: (string) ->
    wait.for(this.command, string)

  # Run vim code
  exec: (code, callback) ->
    @session.request 'vim_eval', [code], callback

  exec_blocking: (code) ->
    wait.form(this.exec, code)

  # Var accessors
  # wrap vim_{get,set}_var

  # Get a variable by name
  # This function blocks
  getvar: (name) ->
    this.request_blocking('vim_get_var', name)

  # Set a variable to a specific value
  # This function blocks
  setvar: (name, value) ->
    this.request_blocking('vim_set_var', name, value)

  # Get a VVar
  # This function blocks
  getvvar: (name) ->
    this.request_blocking('vim_get_vvar', name)

  # Option accessors
  # wrap vim_{get,set}_option

  # Get an option
  # This function blocks
  getopt: (name) ->
    this.request_blocking('vim_get_option', name)

  # Set an option
  # This function blocks
  setopt: (name, value) ->
    this.request_blocking('vim_set_option', name, value)

  getruntimepaths: ->
    this.request_blocking('vim_list_runtime_paths')

  replace_termcodes: (string, from=false, do_lt=true, special=true) ->
    this.request_blocking('vim_replace_termcodes', string, from, do_lt, special)

  # Editor interaction
  
  getbuffers: ->
    this.request_blocking('vim_get_buffers')

  getwindows: ->
    this.request_blocking('vim_get_windows')

  gettabs: ->
    this.request_blocking('vim_get_tabpages')

  cwd: (wd) ->
    this.request_blocking('vim_change_directory', wd)

  input: (bytes) ->
    this.request_blocking('vim_input', bytes)

  feedkeys: (keys, options='', escape_csi=true) ->
    this.request_blocking('vim_feedkeys', keys, options, escape_csi)

  quit: ->
    this.command_blocking('qa!')

  # Vim UI

  put_msg: (msg) ->
    this.request_blindly('vim_out_write', msg)

  put_err: (err) ->
    this.request_blindly('vim_err_write', msg)

  # UI Support

  attach_ui: (width, height, colours, cb) ->
    this.request('ui_attach', [width, height, colours], cb)

  detach_ui: ->
    this.request_blocking('ui_detach')

  resize_ui: (w, h) ->
    this.request_blind('ui_try_resize', w, h)

  strwidth: (string) ->
    this.request_blocking('vim_strwidth', string)
 
module.exports = NeoAPI
