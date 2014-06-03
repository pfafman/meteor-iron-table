
###
Template.ironTableForm.created = ->
    #console.log('ironTableForm created')
###

#Template.ironTableForm.rendered = ->
  #console.log("ironTableForm rendered")
  # Handle checkbox carry over....  THIS IS A HACK !!!
  #$('input:checkbox').removeAttr('checked')
  #for col in @data.columns
    #if col.checkbox and col.checked
      #$("[name=#{col.key}]").attr('checked','checked')


#Template.ironTableFormItem.rendered = ->
#  console.log("ironTableFormItem rendered")

Template.ironTableFormItem.helpers
  textArea: ->
    @displayType is 'textarea'

#  disabled: ->
#    console.log("disabled", @)
#    if @static
#      "disabled"
