AutocompleteTelluriumView = require './autocomplete-tellurium-view'
{CompositeDisposable, Directory} = require 'atom'
socketIO = require('socket.io-client')
minimatch = require('minimatch')
path = require('path')

module.exports = AutocompleteTellurium =
  enabled: false
  targets: []

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @io = socketIO('http://localhost:10000')
    @telluriumView = new AutocompleteTelluriumView
    @telluriumView.init()
    @telluriumView.setStatus('Tellurium: On')

    atom.commands.add 'atom-text-editor',
      'tellurium:enable-complete': =>
        @enabled = true
      'tellurium:disable-complete': =>
        @enabled = false

    atom.workspace.observeTextEditors (editor) =>
      file = @retrieveConfigFile(editor.getPath())
      return unless file

      @targetFromFile(file)
        .then(@registerTarget.bind(this))

    atom.workspace.observeActivePaneItem (item) =>
      console.log(item.getPath())

    @io.on 'connect', =>
      console.log "Connected to socket (#{@io.id})"

      @targets.forEach (target) => @notifyServer(target)

    @io.on 'complete', (data) =>
      return unless @enabled

      editor = atom.workspace.getActiveTextEditor()
      @complete(editor, data)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @telluriumView.destroy()
    @telluriumTile?.destroy()

  consumeStatusBar: (statusBar) ->
    console.log(statusBar)
    @telluriumTile = statusBar.addLeftTile
      item: @telluriumView, priority: -1

  retrieveConfigFile: (path) ->
    dir = new Directory(path)
    configFile = null

    while !dir.isRoot()
      dir = dir.getParent()
      tempFile = dir.getFile('.tellurium')

      if tempFile.existsSync() && tempFile.isFile()
        configFile = tempFile
        break

    configFile

  targetFromFile: (file) ->
    new Promise (resolve, reject) =>
      return reject('File is ' + file) unless file

      target = {}

      @readJsonFile(file)
        .then (json) =>
          target.config = json
          target.configFile = file

          file.onDidChange =>
            @readJsonFile(file)
              .then (json) => target.config = json

          resolve(target)

  registerTarget: (target) ->
    @targets ?= []
    existing = @targets.find (t) -> t.configFile.getPath() == target.configFile.getPath()

    unless existing
      @targets.push(target)
      @notifyServer(target)

  getTarget: (path) ->
    file = @retrieveConfigFile(path)
    return unless file

    @targets.find (t) -> t.configFile.getPath() == file.getPath()

  readJsonFile: (file) ->
    new Promise (resolve, reject) =>
      parseJSON = (data) => resolve(JSON.parse(data))

      file
        .read(false)
        .then(parseJSON)
        .catch(reject)

  notifyServer: (target) ->
    @io.emit('createSession', { configFile: target.configFile.getPath(), config: target.config })

  complete: (editor, completionInfo) ->
    codePath = editor.getPath()
    target = @getTarget(codePath)
    return unless target

    { config, configFile } = target

    config.files.some (file) =>
      filePattern = path.join(configFile.getParent().getPath(), file)

      if minimatch(codePath, filePattern) && minimatch(completionInfo.url, config.url)
        editor.insertText(completionInfo.code, autoIndent: true)
        editor.insertNewline()
