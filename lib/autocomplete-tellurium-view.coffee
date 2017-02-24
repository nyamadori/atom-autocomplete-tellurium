class AutocompleteTelluriumView extends HTMLElement
  init: ->
    @classList.add('tellurium-view', 'inline-block')
    @disable()

  enable: ->
    @classList.add('status-enable')
    @textContent = 'Tellurium: On'

  disable: ->
    @classList.remove('status-enable')
    @textContent = 'Tellurium: Off'

module.exports =
  document.registerElement 'tellurium-status',
    prototype: AutocompleteTelluriumView.prototype, extends: 'div'
