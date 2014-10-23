
capitalize = (string) ->
  string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
  

Template.ironTableFormItem.rendered = ->
  #console.log("ironTableFormItem rendered")
  $('[rel="tooltip"]').tooltip()


Template.ironTableFormItem.helpers
  textArea: ->
    @displayType is 'textarea'


  inputTemplate: ->
    rtn = 'ironTableFormInput'
    switch @displayType
      when 'textarea', 'select', 'checkbox'
        type = capitalize(@displayType)
        rtn = "ironTableForm#{type}"
      else
        rtn = 'ironTableFormInput'
    rtn
