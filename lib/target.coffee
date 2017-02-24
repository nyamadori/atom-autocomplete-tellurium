minimatch = require('minimatch')
path = require('path')

class Target
  @loadFromFile: (file) ->
    new Promise (resolve, reject) =>
      file
        .read(false)
        .then (data) =>
          resolve(new Target(JSON.parse(data), file))
        .catch(reject)

  constructor: (@config, @configFile) ->

  isTargetUrl: (url) ->
    minimatch(url, @config.url)

  isTargetFile: (filePath) ->
    @config.files.some (file) =>
      pattern = path.join(@configFile.getParent().getPath(), file)
      minimatch(filePath, pattern)

  isTarget: (url, path) ->
    @isTargetUrl(url) && @isTargetFile(path)

module.exports = Target
