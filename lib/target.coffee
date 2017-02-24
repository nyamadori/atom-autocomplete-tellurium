minimatch = require('minimatch')
path = require('path')
{ Emitter } = require 'event-kit'

readJsonFile = (file) ->
  new Promise (resolve, reject) =>
    file.read(false)
      .then (data) =>
        resolve(JSON.parse(data))
      .catch(reject)

class Target
  @loadFromFile: (file) ->
    new Promise (resolve, reject) =>
      readJsonFile(file)
        .then (config) ->
          target = new Target(config, file)
          resolve(target)
        .catch(reject)

  constructor: (@config, @configFile) ->
    @emitter = new Emitter

    @configFile.onDidChange =>
      readJsonFile(@configFile)
        .then (config) =>
          @config = config
          @emitter.emit('did-change-config', @)

  onDidChangeConfig: (callback) ->
    @emitter.on('did-change-config', callback)

  isTargetUrl: (url) ->
    minimatch(url, @config.url)

  isTargetFile: (filePath) ->
    @config.files.some (file) =>
      pattern = path.join(@configFile.getParent().getPath(), file)
      minimatch(filePath, pattern)

  isTarget: (url, path) ->
    @isTargetUrl(url) && @isTargetFile(path)

module.exports = Target
