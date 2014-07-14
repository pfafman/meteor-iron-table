
Template.ironTableFormItem.rendered = ->
  #console.log("ironTableFormItem rendered")
  $('[rel="tooltip"]').tooltip()


Template.ironTableFormItem.helpers
  textArea: ->
    @displayType is 'textarea'

