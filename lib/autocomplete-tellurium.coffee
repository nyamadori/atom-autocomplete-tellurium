{CompositeDisposable, Directory} = require('atom')
socketIO = require('socket.io-client')
minimatch = require('minimatch')
path = require('path')
AutocompleteTelluriumView = require('./autocomplete-tellurium-view')
Target = require('./target')

module.exports = AutocompleteTellurium =
  active: false
  enabled: false
  targets: []

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @io = socketIO('http://localhost:10000')
    @telluriumView = new AutocompleteTelluriumView
    @telluriumView.init()

    atom.commands.add 'atom-text-editor',
      'tellurium:enable-complete': =>
        @enable()
      'tellurium:disable-complete': =>
        @disable()

    atom.workspace.observeTextEditors (editor) =>
      file = @retrieveConfigFile(editor.getPath())
      return unless file

      Target.loadFromFile(file)
        .then(@registerTarget.bind(this))
        .then(@showStatusTile.bind(this))

    atom.workspace.onDidChangeActivePaneItem (item) =>
      @showStatusTile()

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
    @statusBar = statusBar

  enable: ->
    @enabled = true
    @telluriumView?.enable()

  disable: ->
    @enabled = false
    @telluriumView?.disable()

  showStatusTile: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    path = activeEditor.getPath()
    target = @getTarget(path)
    return unless target

    @active = target.isTargetFile(path)

    if @active
      @telluriumTile = @statusBar.addLeftTile
        item: @telluriumView, priority: -1
    else
      @telluriumTile?.destroy()

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

  registerTarget: (target) ->
    @targets ?= []
    existing = @targets.find (t) -> t.configFile.getPath() == target.configFile.getPath()

    unless existing
      target.onDidChangeConfig =>
        @notifyServer(target)

      @targets.push(target)
      @notifyServer(target)

  getTarget: (path) ->
    file = @retrieveConfigFile(path)
    return unless file

    @targets.find (t) -> t.configFile.getPath() == file.getPath()

  notifyServer: (target) ->
    @io.emit('createSession', { configFile: target.configFile.getPath(), config: target.config })

  complete: (editor, completionInfo) ->
    codePath = editor.getPath()
    target = @getTarget(codePath)
    return unless target

    if target.isTarget(completionInfo.url, codePath)
      editor.insertText(completionInfo.code, autoIndent: true)
      editor.insertNewline()
