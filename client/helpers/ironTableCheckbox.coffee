

Template.ironTableCheckbox.rendered = ->
  @active = new ReactiveVar(false)


Template.ironTableCheckbox.helpers
  doEdit: ->
    #console.log('doEdit', @column?.contenteditable, Template.instance().active?.get())
    @column?.contenteditable and Template.instance().active?.get()

  checkedMark: ->
    @column?.checkedMark or 'fa-check-square-o'

  notCheckMark: ->
    if not @column?.blankOnNotChecked
      @column?.notCheckMark or 'fa-square-o'

Template.ironTableCheckbox.events

  "click .check-mark": (e, tmpl) ->
    if Template.parentData(1).editOk
      tmpl.active.set(true)
      #console.log('check mark click', @record._id, e, tmpl.active.get())
      

  "mouseenter .check-mark": (e, tmpl) ->
    #console.log('mouseenter')

  "mouseleave .check-mark": (e, tmpl) ->
    #console.log('mouseleave')
    tmpl.active.set(false)

  "mouseleave .check-mark-checkbox": (e, tmpl) ->
    #console.log('mouseleave checkbox')
    tmpl.active.set(false)

  "click .check-mark-checkbox": (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    if Template.parentData(1).editOk
      console.log("change checkbox value", @value)
      if @value
        newValue = false
      else
        newValue = true

      if Router.current?()?.classID is "IronTableController"
        console.log("Submit Value Change", @dataKey, @value, '->', newValue)
        data = {}
        data[@dataKey] = newValue
        Router.current().updateThisRecord?(@record._id, data, 'inlineUpdate')
