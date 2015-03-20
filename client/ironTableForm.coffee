
capitalize = (string) ->
  string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()
  

Template.ironTableFormItem.onRendered ->
  #console.log("ironTableFormItem rendered")
  $('[rel="tooltip"]').tooltip()
  $('select').material_select()
  $('.datepicker').pickadate
    selectMonths: false
    selectYears: false


Template.ironTableFormItem.helpers
  textArea: ->
    @displayType is 'textarea'

  forKey: ->
    if @displayType isnt 'select'
      @key


  inputTemplate: ->
    rtn = 'ironTableFormInput'
    switch @displayType
      when 'textarea', 'select', 'checkbox', 'date'
        type = capitalize(@displayType)
        rtn = "ironTableForm#{type}"
      else
        rtn = 'ironTableFormInput'
    rtn

  showHelpText: ->
    @helpText? and not @static?
