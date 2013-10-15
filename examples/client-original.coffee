thrift = require('thrift')
PingService = require('../test/gen-nodejs/PingService.js')
ttypes = require('../test/gen-nodejs/ping_types')

connection = thrift.createConnection('localhost', 9090)
client = thrift.createClient(PingService, connection)

ping = new ttypes.PingMsg
  msg: 'Hello'

client.ping ping, (err, res) ->
  if err
    console.error err
  else
    console.log 'pong:', res

    connection.end()
