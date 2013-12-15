
read = require 'read'
{checkers} = require './checkers'
log = require './log'

#========================================================================

exports.Prompter = class Prompter 

  constructor : (@_fields) -> @_data = {}
  data        : ()         -> @_data
  clear       : (k)        -> delete @_data[k]

  #-------------------

  run : (cb) ->
    err = null
    for k,v of @_fields
      await @read_field k, v, defer err
      break if err?
    cb err

  #-------------------

  read_field : (k,{prompt,passphrase,checker,confirm,defval}, cb) ->
    err = null
    ok = false
    first = true

    until ok
      p = if first then (prompt + ": ")
      else (prompt + " (" + checker.hint + "): ")
      first = false

      obj = { prompt : p } 
      if passphrase
        obj.silent = true
        obj.replace = "*"
      if (d = @_data[k])? or (d = defval)?
        obj.default = d
        obj.edit = true
      await read obj, defer err, res, isDefault
      break if err?

      if checker?.f? and not checker.f res then ok = false
      else if not confirm? or isDefault then ok = true
      else
        delete obj.default
        obj.edit = false
        obj.prompt = confirm.prompt + ": "
        await read obj, defer err, res2
        if res2 isnt res
          ok = false
          log.warn "Passphrases didn't match! Try again."
        else
          ok = true
      if ok
        @_data[k] = res if not(isDefault) or not(@_data[k]?)

    cb err

#========================================================================

