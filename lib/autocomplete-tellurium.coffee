AutocompleteTelluriumView = require './autocomplete-tellurium-view'
{CompositeDisposable, Directory} = require 'atom'
socketIO = require('socket.io-client')
minimatch = require('minimatch')
path = require('path')

module.exports = AutocompleteTellurium =
  autocompleteTelluriumView: null
  modalPanel: null
  subscriptions: null
  enabled: false
  io: null

  activate: (state) ->
    @autocompleteTelluriumView = new AutocompleteTelluriumView(state.autocompleteTelluriumViewState)
    @subscriptions = new CompositeDisposable

    @io = socketIO('http://localhost:10000')

    atom.commands.add 'atom-text-editor',
      'tellurium:enable-complete': =>
        @enabled = true
      'tellurium:disable-complete': =>
        @enabled = false

    atom.workspace.observeTextEditors (editor) =>
      @notifyServer(editor)

    @io.on 'connect', =>
      console.log "Connected to socket (#{@io.id})"

      for editor in atom.workspace.getTextEditors()
        @notifyServer(editor)

    @io.on 'complete', (data) =>
      return unless @enabled

      editor = atom.workspace.getActiveTextEditor()
      @complete(editor, data)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @autocompleteTelluriumView.destroy()

  serialize: ->
    autocompleteTelluriumViewState: @autocompleteTelluriumView.serialize()

  getConfigFile: (path) ->
    dir = new Directory(path)
    configFile = null

    while !dir.isRoot()
      dir = dir.getParent()
      tempFile = dir.getFile('.tellurium')

      if tempFile.existsSync() && tempFile.isFile()
        configFile = tempFile
        break

    configFile

  readConfig: (file) ->
    new Promise (resolve, reject) =>
      read = (data) => resolve(JSON.parse(data))

      file
        .read(false)
        .then(read, reject)

  notifyServer: (editor) ->
    new Promise (resolve, reject) =>
      configFile = @getConfigFile(editor.getPath())
      return resolve() unless configFile

      @readConfig(configFile)
        .then (config) =>
          @io.emit('createSession', { configFile: configFile.getPath(), config: config })
          resolve()
        .catch(reject)

  complete: (editor, completionInfo) ->
    codeFile = editor.getPath()
    configFile = @getConfigFile(codeFile)

    @readConfig(configFile)
      .then (config) =>
        console.log(completionInfo, completionInfo.url, config.url)
        for filePattern in config.files
          filePattern =
            path.join(configFile.getParent().getPath(), filePattern)

          if minimatch(codeFile, filePattern) && minimatch(completionInfo.url, config.url)
            editor.insertText(completionInfo.code, autoIndent: true)
            editor.insertNewline()
