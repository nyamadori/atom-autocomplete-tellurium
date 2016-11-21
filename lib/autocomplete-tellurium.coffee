AutocompleteTelluriumView = require './autocomplete-tellurium-view'
{CompositeDisposable} = require 'atom'

module.exports = AutocompleteTellurium =
  autocompleteTelluriumView: null
  modalPanel: null
  subscriptions: null

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

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @autocompleteTelluriumView.destroy()

  serialize: ->
    autocompleteTelluriumViewState: @autocompleteTelluriumView.serialize()

  toggleCapture: ->
    console.log 'AutocompleteTellurium was toggled!'
    atom.workspace.open(null, split: 'down')

  complete: ->
    console.log 'AutocompleteTellurium was completed!'
    # engine に補完リクエストを送信
