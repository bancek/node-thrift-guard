thrift = require('thrift')
thriftGuard = require('../src/index')
PingService = require('../test/gen-nodejs/PingService.js')
ttypes = require('../test/gen-nodejs/ping_types')

client = thriftGuard('localhost', 9090, PingService, ttypes)

ping = new ttypes.PingMsg
  msg: 'Hello'

client.ping ping, (err, res) ->
  if err
    console.error err
  else
    console.log 'pong:', res

    client.close()
