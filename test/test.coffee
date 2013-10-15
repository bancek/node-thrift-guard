_ = require('lodash')
should = require('chai').should()

thrift = require('thrift')
thriftGuard = require('../src/index')
PingService = require('./gen-nodejs/PingService.js')
ttypes = require('./gen-nodejs/ping_types')

describe 'Thrift Guard', ->
  it 'should send message', (done) ->
    server = thrift.createServer(PingService,
      ping: (msg, cb) ->
        pong = new ttypes.PongMsg
          msg: msg.msg

        cb null, pong
    )

    server.listen 5555

    client = thriftGuard('localhost', 5555, PingService, ttypes)

    ping = new client.PingMsg(msg: 'Hello')

    client.ping ping, (err, res) ->
      should.not.exist err

      res.msg.should.equal 'Hello'

      client.close()
      server.close()

      done()

  it 'should get error if server is not listening', (done) ->
    client = thriftGuard('localhost', 5555, PingService, ttypes)

    ping = new client.PingMsg(msg: 'Hello')

    client.ping ping, (err, res) ->
      should.exist err

      client.close()

      done()

  it 'should timeout if server does not answer', (done) ->
    server = thrift.createServer(PingService,
      ping: (msg, cb) ->
    )

    server.listen 5555

    opts =
      timeout: 50

    client = thriftGuard('localhost', 5555, PingService, ttypes, opts)

    ping = new client.PingMsg(msg: 'Hello')

    client.ping ping, (err, res) ->
      should.exist err

      client.close()
      server.close()

      done()

  it 'should send multiple message', (done) ->
    queue = []

    server = thrift.createServer(PingService,
      ping: (msg, cb) ->
        queue.unshift([msg, cb])

        if msg.msg == 'World'
          for [msg, cb] in queue
            pong = new ttypes.PongMsg
              msg: msg.msg

            cb null, pong

          queue = []
    )

    server.listen 5555

    client = thriftGuard('localhost', 5555, PingService, ttypes)

    counter = 0

    client.ping new client.PingMsg(msg: 'Hello'), (err, res) ->
      should.not.exist err

      counter.should.equal 1
      counter++

      res.msg.should.equal 'Hello'

      client.close()
      server.close()

      done()

    client.ping new client.PingMsg(msg: 'World'), (err, res) ->
      should.not.exist err

      counter.should.equal 0
      counter++

      res.msg.should.equal 'World'

  it 'should export methods and ttypes', (done) ->
    client = thriftGuard('localhost', 5555, PingService, ttypes)

    names = (name for name of client when client.hasOwnProperty(name))
    names.sort()

    names.should.eql ['PingMsg', 'PongMsg', 'close', 'ping']
    
    client.close()
    done()
