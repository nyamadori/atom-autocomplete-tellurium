AutocompleteTelluriumView = require './autocomplete-tellurium-view'
{CompositeDisposable} = require 'atom'
socketIO = require('socket.io-client')

module.exports = AutocompleteTellurium =
  autocompleteTelluriumView: null
  modalPanel: null
  subscriptions: null
  capturing: false
  io: null
  sessionId: null
  editor: null

  activate: (state) ->
    @autocompleteTelluriumView = new AutocompleteTelluriumView(state.autocompleteTelluriumViewState)
    # @modalPanel = atom.workspace.addModalPanel(item: @autocompleteTelluriumView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'autocomplete-tellurium:toggle-capture': =>
        @toggleCapture()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'autocomplete-tellurium:complete': =>
        @complete()
    @subscriptions.add atom.commands.add 'atom-workspace',
      'autocomplete-tellurium:sessionId': =>
        console.log(this.sessionId)

    atom.workspace.observeTextEditors (editor) =>
      @editor = editor

    @io = socketIO('http://localhost:9000')
    @io.on 'connect', =>
      console.log "Socket ID: #{@io.id}"

    @io.on 'complete', (data) =>
      @editor.insertText(data.code)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @autocompleteTelluriumView.destroy()

  serialize: ->
    autocompleteTelluriumViewState: @autocompleteTelluriumView.serialize()

  startCapture: ->
    @io.emit 'createSession', generator: 'capybara', (res) =>
      @sessionId = res.sessionId

    @capturing = true

  endCapture: ->
    @io.emit('destroySession', {message: 'destroySession', sessionId: @sessionId})
    @capturing = false

  toggleCapture: ->
    if @capturing
      @endCapture()
      @capturing = false
    else
      @startCapture()
      @capturing = true

  complete: ->
    console.log 'AutocompleteTellurium was completed!'
    # engine に補完リクエストを送信
