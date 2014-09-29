
Template.ironTableSelect.rendered = ->
  @active = new ReactiveVar(false)


Template.ironTableSelect.helpers
  doEdit: ->
    @column?.contenteditable? and Template.instance().active?.get()

  getValue: ->
    @select?[@value] or @value


Template.ironTableOptions.helpers
  options: ->
    if @select?
      rtn = []
      if _.isArray(@select)
        for elm in @select
          rtn.push
            key: elm
            val: elm
            selected: if @value is elm then 'selected'
      else if _.isObject(@select)
        for key, val of @select
          rtn.push
            key: key
            val: val
            selected: if @value is key then 'selected'
      rtn


Template.ironTableSelect.events

  "click .select-view": (e, tmpl) ->
    if Template.parentData(1).editOk
      console.log('view clicked', @record._id, e, tmpl)
      tmpl.active.set(true)
      #Session.set("ironTableActiveRecordId", @record._id)

  "mouseenter .select": (e, tmpl) ->
    #console.log('mouseenter')

  "mouseleave .select": (e, tmpl) ->
    #console.log('mouseleave')
    Template.instance().active.set(false)
    #Session.set("ironTableActiveRecordId", null)

  "mouseleave .select-div": (e, tmpl) ->
    tmpl.active.set(false)
    #Session.set("ironTableActiveRecordId", null)

  "change select": (e, tmpl) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    if Template.parentData(1).editOk
      console.log("change select value", @dataKey, @value, $(e.target).val())

      if Router.current?()?.classID is "IronTableController"
        console.log("Submit Value Change", @dataKey, @value, '->', $(e.target).val())
        data = {}
        data[@dataKey] = $(e.target).val()
        Router.current().updateThisRecord?(@record._id, data, 'inlineUpdate')



