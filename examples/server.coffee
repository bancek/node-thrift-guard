thrift = require('thrift')
PingService = require('../test/gen-nodejs/PingService.js')
ttypes = require('../test/gen-nodejs/ping_types')

server = thrift.createServer(PingService,
  ping: (msg, cb) ->
    console.log 'ping', msg.msg

    pong = new ttypes.PongMsg
      msg: msg.msg

    cb null, pong
)

server.listen 9090
