_ = require('lodash')
thrift = require('thrift')
{Pool} = require('generic-pool')

MAX_POOL_SIZE = 50
IDLE_TIMEOUT_MILLIS = 30000

class ThriftClient
  constructor: (@host, @port, @cls, @onEnd, @options) ->
    @verbose = options.verbose
    @closeCalled = no

    @connect()

  connect: =>
    @connection = thrift.createConnection(@host, @port, @options)

    @connection.on 'error', @onError
    @connection.on 'close', @onClose
    @connection.on 'timeout', @onTimeout

    @thrift = thrift.createClient(@cls, @connection)

  handleErrors: (err) =>
    # onEnd must be called before requests callbacks
    # no need to call onEnd if closed from outside
    @onEnd?() if not @closeCalled

    if @thrift?
      reqs = @thrift._reqs

      for id of reqs when reqs.hasOwnProperty(id)
        cb = reqs[id]
        delete reqs[id]

        cb(err)

      @thrift = null

  close: =>
    @closeCalled = yes

    @connection?.connection.destroy()
    @connection = null

  onError: (err) =>
    @handleErrors(err ? new Error('Connection error'))
    console.warn("Thrift error: #{@host}:#{@port}: #{err}", err) if @verbose

  onClose: =>
    @handleErrors(new Error('Connection closed'))
    console.warn("Thrift close: #{@host}:#{@port}") if @verbose

  onTimeout: =>
    @handleErrors(new Error('Connection timeout'))
    console.warn("Thrift timeout: #{@host}:#{@port}") if @verbose

class ThriftGuard
  constructor: (@host, @port, @cls, @ttypes, @options) ->
    @options = {} if not @options?

    @initPool()
    @initProxy()

  initPool: =>
    @pool = Pool(
      name: 'thrift'
      create: @createClient
      destroy: @destroyClient
      max: @options.maxPoolSize ? MAX_POOL_SIZE
      idleTimeoutMillis: @options.poolIdleTimeoutMillis ? IDLE_TIMEOUT_MILLIS
      log: @options.verbose
    )

  initProxy: =>
    @proxy = {}

    methods = @cls.Client.prototype

    isValidMethod = (value, name) =>
      methods.hasOwnProperty(name) and \
        name.indexOf('send_') is -1 and \
        name.indexOf('recv_') is -1 and \
        typeof value is 'function'

    _(methods).forEach (value, name) =>
      if isValidMethod(value, name)
        @proxy[name] = => @call(name, arguments)

    ttypes = @ttypes

    _(ttypes).forEach (value, name) =>
      if ttypes.hasOwnProperty(name)
        @proxy[name] = value

    @proxy.close = @close

  createClient: (cb) =>
    onEnd = =>
      @pool.destroy(c)

    c = new ThriftClient(@host, @port, @cls, onEnd, @options)

    cb null, c

  destroyClient: (client) =>
    client.close()

  call: (name, argsObj) =>
    # transform arguments to array
    args = (arg for arg in argsObj)

    cb = args.pop()

    @pool.acquire (err, client) =>
      return cb(err) if err?

      args.push (err, res) =>
        @pool.release client

        cb(err, res)

      t = client.thrift
      t[name].apply(t, args)

  close: =>
    @pool.drain =>
      @pool.destroyAllNow()

guard = (host, port, cls, ttypes, options) ->
  guard = new ThriftGuard(host, port, cls, ttypes, options)

  guard.proxy

guard.ThriftGuard = ThriftGuard

module.exports = guard
