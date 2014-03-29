
###
Template.ironTableForm.created = ->
    #console.log('ironTableForm created')
###

Template.ironTableForm.rendered = ->
  # Handle checkbox carry over....  THIS IS A HACK !!!
  $('input:checkbox').removeAttr('checked')
  for col in @data.columns
      if col.checkbox and col.checked
          $("[name=#{col.key}]").attr('checked','checked')


Template.ironTableForm.helpers
  disabled: ->
    if @static
      "disabled"