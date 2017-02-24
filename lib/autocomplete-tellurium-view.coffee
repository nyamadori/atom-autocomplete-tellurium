class AutocompleteTelluriumView extends HTMLElement
  init: ->
    @classList.add('tellurium-view')
    @classList.add('inline-block')

  setStatus: (status) ->
    @textContent = status

module.exports =
  document.registerElement 'tellurium-status',
    prototype: AutocompleteTelluriumView.prototype, extends: 'div'
