sys = require('sys')
exec = require('child_process').exec
fs = require('fs')

binaryRRDFile = require('./binaryFile.js')
RRDReader = require('./rrdFile.js').RRDFile

class RRD
  constructor: (@filename) ->

  destroy: (cb) ->
    fs.unlink(@filename, cb)

  create: (ds, rra, cb) ->
    exec("rrdtool create #{@filename} --start #{(new Date).valueOf()} --step 1 #{ds} #{rra}", cb)

  update: (time, value, cb) ->
    # exec("rrdtool update #{@filename} #{time.valueOf()}:#{value}", cb)
    this._rrdExec("update", "#{time.valueOf()}:#{value}", cb)

  fetch: (cb) ->
    datasources = {}

    binaryRRDFile.FetchBinaryURLAsync @filename, (binfile) ->
      rrdReader = new RRDReader(binfile)
      numDatasources = rrdReader.getNrDSs()

      cb _datasource_info(rrdReader, datasourceNum) for datasourceNum in [0..numDatasources-1]

  _datasource_info = (rrdReader, dsNum) ->
    datasource = rrdReader.getDS(dsNum)

    values = []
    rra = rrdReader.getRRA(dsNum)
    for rowNum in [0..rra.row_cnt-1]
      do (rowNum) ->
        values.push(rra.getElFast(rowNum, dsNum))

    result = {}
    result[datasource.getName()] = values
    return result

  _rrdExec: (command, cmd_args, cb) ->
    cmd = "rrdtool #{command} #{@filename} #{cmd_args}"
    console.log cmd
    # exec(cmd, (err, stdout, stdin) ->
    #   console.log err)
    exec cmd, cb

exports.RRD = RRD
