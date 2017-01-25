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

    @io = socketIO('http://localhost:9000')

    atom.commands.add 'atom-text-editor',
      'tellurium:enable-complete': =>
        @enabled = true
      'tellurium:disable-complete': =>
        @enabled = false

    atom.workspace.onDidStopChangingActivePaneItem (item) =>
      configFile = @getConfigFile(item.getPath())
      return unless configFile

      @readConfig(configFile)
        .then (config) =>
          @io.emit('createSession', { configFile: configFile.getPath(), config: config })
        .catch (e) => console.error(e)

    @io.on 'connect', =>
      console.log "Socket ID: #{@io.id}"

    @io.on 'complete', (data) =>
      return unless @enabled

      activeEditor = atom.workspace.getActiveTextEditor()
      activeEditorPath = activeEditor.getPath()
      configFile = @getConfigFile(activeEditorPath)

      @readConfig(configFile)
        .then (config) =>
          for filePattern in config.files
            filePattern =
              path.join(configFile.getParent().getPath(), filePattern)

            if minimatch(activeEditorPath, filePattern)
              activeEditor.insertText(data.code)
              activeEditor.insertNewline()

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

  normalizeConfig: (rawConfig) ->
    normalized = Object.assign({}, rawConfig)
    normalized.files = [].concat(normalized.files)
    normalized

  readConfig: (file) ->
    new Promise (resolveCb, rejectCb) =>
      read = (data) => resolveCb(@normalizeConfig(JSON.parse(data)))

      file
        .read(false)
        .then(read, rejectCb)
