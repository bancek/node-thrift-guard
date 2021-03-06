fs = require 'fs'
{spawn} = require 'child_process'
path = require 'path'
file = require 'file'

task 'build', 'Build lib from src', ->
  spawn('coffee', ['--compile', '--output', 'lib/', 'src/'], stdio: 'inherit')

task 'coverage', 'Build cov-lib from src', (callback) ->
  spawn('coffeeCoverage', ['src', 'src'], stdio: 'inherit').on 'close', ->
    out = fs.openSync('coverage.html', 'w')

    spawn('mocha', [
      '--compilers', 'coffee:coffee-script',
      '--reporter', 'html-cov'],
      stdio: ['ignore', out, process.stderr]
    ).on 'close', ->
      fs.closeSync(out)

      file.walkSync 'src', (base, dirs, files) ->
        files.forEach (file) ->
          if /\.js$/.test(file)
            fs.unlinkSync(path.join(base, file))

      callback?()

task 'test', 'Run Mocha tests', (callback) ->
  spawn 'mocha', ['--compilers', 'coffee:coffee-script', '--recursive', 'test'], stdio: 'inherit'

task 'test-thrift-gen', 'Generate thrift files for tests', (callback) ->
  spawn 'thrift', ['-o', 'test', '--gen', 'js:node', 'test/ping.thrift'], stdio: 'inherit'
