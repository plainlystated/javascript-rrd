sys = require('sys')
exec = require('child_process').exec
fs = require('fs')

binaryRRDFile = require('./binaryFile.js')
RRDReader = require('./rrdFile.js').RRDFile

class RRD
  constructor: (@filename) ->

  create: (ds, rra, cb) ->
    cmd = "rrdtool create #{@filename} --start #{_rrdTime(new Date)} --step 5 #{ds} #{rra}"
    console.log " - #{cmd}"
    exec(cmd, cb)

  destroy: (cb) ->
    fs.unlink(@filename, cb)

  rrdExec: (command, cmd_args, cb) ->
    cmd = "rrdtool #{command} #{@filename} #{cmd_args}"
    console.log cmd
    exec cmd, cb

  update: (time, value, cb) ->
    this.rrdExec("update", "#{_rrdTime(time)}:#{value}", cb)

  fetch: (cb) ->
    datasources = {}

    binaryRRDFile.FetchBinaryURLAsync @filename, (binfile) ->
      rrdReader = new RRDReader(binfile)
      numDatasources = rrdReader.getNrDSs()

      cb _datasourceInfo(rrdReader, datasourceNum) for datasourceNum in [0..numDatasources-1]

  _datasourceInfo = (rrdReader, dsNum) ->
    datasource = rrdReader.getDS(dsNum)

    values = []
    rra = rrdReader.getRRA(dsNum)
    for rowNum in [0..rra.row_cnt-1]
      do (rowNum) ->
        values.push(rra.getElFast(rowNum, dsNum))

    result = {}
    result[datasource.getName()] = values
    return result


  _rrdTime = (date) ->
    return Math.round(date.valueOf() / 1000)

exports.RRD = RRD
