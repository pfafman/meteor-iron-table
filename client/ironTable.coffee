
DEBUG = false

getCurrentIronTableController = ->
  if Router.current?()?.classID is "IronTableController"
    Router.current()
  #else
  #    console.log("Bad controller", Router.current?())
  #    null


t9nIt = (string) ->
  T9n?.get?(string) or string
  
Template.registerHelper 'irtblT9nit', (string) ->
  t9nIt(string)

#Template.ironTable.onCreated ->
#  console.log("ironTable created")

sizeCalc = ->

  if getCurrentIronTableController()?.inabox
    outerSelector = '.iron-table-container .box'
    box = 'box'
  else
    outerSelector = '.iron-table-container'
    box = ''

  h  = $(outerSelector).innerHeight()
  h1 = $('.iron-table-heading')?.outerHeight()
  h2 = $('.iron-table-filter')?.outerHeight()
  h3 = $('.iron-table-nav')?.outerHeight()
  ht = $('.iron-table-container table').outerHeight()

  hSet = h - h1 - h2 - h3 - 20
  if hSet <= ht
    $('.iron-table-container .table-container').height(hSet)
    $(outerSelector).height('')
  else
    $('.iron-table-container .table-container').height(ht)
    if h >= ht + h1 + h2 + h3 + 30
      #console.log('sizeCalc set outer', ht + h1 + h2 + h3 + 30)
      #$(outerSelector).height(ht + h1 + h2 + h3 + 30)
    else
      $(outerSelector).height('')

  ha = $('.iron-table-container .table-container').height()
  console.log("sizeCalc #{box}", h, h1, h2, h3, hSet, ha, ht)
  



Template.ironTable.onRendered ->
  $('[rel="tooltip"]')?.tooltip('destroy')
  $('[rel="tooltip"]')?.tooltip()
  
  $( window ).on('resize', sizeCalc)


Template.ironTable.onDestroyed ->
  $('[rel="tooltip"]')?.tooltip('destroy')
  $( window ).off('resize')


Template.ironTable.helpers

  inabox: ->
    getCurrentIronTableController()?.inabox

  classes: ->
    if getCurrentIronTableController()?.inabox and getCurrentIronTableController().fullScreenOnSmall
      classes = getCurrentIronTableController().templateClasses
      classes.box += " no-box-on-small"
      classes.container += " full-screen-on-small"
      classes
    else
      getCurrentIronTableController()?.templateClasses

  moreTableClasses: ->
    if getCurrentIronTableController()?.rowLink?
      "hoverable rowlink"

  loading: ->
    not getCurrentIronTableController()?.docsReady() and not getCurrentIronTableController()?.haveData()

  haveData: ->
    getCurrentIronTableController()?.haveData()

  # NOTE: Iron Router 7.1 and Meteor 8.2 not playing well together !?!?!?
  #       Moved from gettting in data to getting from controller in helpers
  #       TODO: Check if this is better in Meteor 0.9

  showFilter: ->
    getCurrentIronTableController()?.showFilter

  recordsName: ->
    getCurrentIronTableController()?.getRecordsName()



Template.ironTable.events

  "click td": (event, tmpl) ->
    if getCurrentIronTableController().rowLink? and not $(event.currentTarget).hasClass('rowlink-skip')
      getCurrentIronTableController().rowLink(@.record)

  
  "click .iron-table-delete-record": (e, tmpl) ->
    e.preventDefault()
    #e.stopImmediatePropagation()
    $('.iron-table-delete-record').tooltip('hide')

    if not currentController = getCurrentIronTableController()
      Materialize.toast(t9nIt "Internal Error: Could not get controller", 3000, 'red')
      return false

    MaterializeModal.confirm
      title: t9nIt "Delete Record"
      message: t9nIt("Are you sure you want to delete") + " #{@recordDisplayName}?"
      callback: (yesNo) =>
        if yesNo
          currentController.removeRecord(@)
    

  "click .iron-table-edit-record": (e, tmpl) ->
    currentController = getCurrentIronTableController()
    if not currentController?.getEditRoute(@_id)?
      e.preventDefault()
      #e.stopImmediatePropagation()
      $('.iron-table-edit-record').tooltip('hide')

      if not currentController
        Materialize.toast(t9nIt "Internal Error: Could not get controller", 3000, 'red')
        false
      else
        currentController.editRecord(@_id)

  "click .show-record": (e, tmpl) ->
    e.preventDefault()
    $("#modal-json-#{@_id}").openModal()

Template.ironTableHeading.helpers

  tableTitle: ->
    t9nIt getCurrentIronTableController()?.getTableTitle()

  showTitleLargeOnly: ->
    getCurrentIronTableController()?.showTitleLargeOnly

  subTitle: ->
    t9nIt getCurrentIronTableController()?.getSubTitle()

  extraLinkTemplate: ->
    getCurrentIronTableController()?.extraLinkTemplate
    
  doDownloadLink: ->
    getCurrentIronTableController()?.doDownloadLink

  showBackButton: ->
    getCurrentIronTableController()?.showBackButton

  showNewButton: ->
    getCurrentIronTableController()?.showNewButton?() or getCurrentIronTableController()?.showNewButton is true

  newRecordRoute: ->
    getCurrentIronTableController()?.newRecordRoute

  newRecordTitle: ->
    getCurrentIronTableController()?.newRecordTitle

  newRecordTooltip: ->
    getCurrentIronTableController()?.newRecordTooltip

  newButtonColor: ->
    getCurrentIronTableController()?.layoutOptions?.newButtonColor or 'green'

  downloadButtonColor: ->
    getCurrentIronTableController()?.layoutOptions?.downloadButtonColor or 'blue'


Template.ironTableHeading.events
  "click #iron-table-new-record": (e, tmpl) ->
    e.preventDefault()
    #e.stopImmediatePropagation()
    if not currentController = getCurrentIronTableController()
      Materialize.toast("Internal Error: Could not get controller", 3000, 'red')
      false
    else
      currentController.newRecord()


  "click #download-link": (e, tmpl) ->
    if not currentController = getCurrentIronTableController()
      Materialize.toast("Internal Error: Could not get controller", 3000, 'red')
      return false

    filename = @tableTitle + '.csv'
    currentController.downloadRecords (error, csv) ->
      if error
        Materialize.toast("Error getting CSV to download", 3000, 'red')
        console.log("Error getting CSV", error)
      else if csv
        console.log("Doing saveAs for CSV") if DEBUG
        blob = new Blob [csv],
          type: "text/csv"
        saveAs?(blob, filename)
        Materialize.toast("Records Downloaded", 3000, 'green')
      else
        Materialize.toast("No data to download", 3000, 'red')


#Template.ironTableFilter.onCreated ->
#  console.log("ironTableFilter created")


Template.ironTableFilter.onRendered ->
  $('select').material_select()


Template.ironTableFilter.helpers
  headers: ->
    getCurrentIronTableController()?.filterHeaders()

  filterValue: ->
    getCurrentIronTableController()?.getFilterValue()

  filterType: ->
    getCurrentIronTableController()?.getSelectedFilterType()

  checked: ->
    if getCurrentIronTableController()?.getSelectedFilterType() and getCurrentIronTableController()?.getFilterValue()
      'checked'


Template.ironTableFilter.events

  "change #filter-column": (e, tmpl) ->
    #e.preventDefault()
    if not currentController = getCurrentIronTableController()
      Materialize.toast("Internal Error: Could not get controller", 3000, 'red')
      return false

    currentController.setFilterColumn(e.target.value)

  "keyup, change #filter-value": (e, tmpl) ->
    #e.preventDefault()
    console.log("filter-value", $(e.target).is(':checked'), e.target.value) if DEBUG
    if not currentController = getCurrentIronTableController()
      Materialize.toast("Internal Error: Could not get controller", 3000, 'red')
      return false
    value = e.target.value
    if getCurrentIronTableController()?.getSelectedFilterType() is 'checkbox'
      value = $(e.target).is(':checked')

    Meteor.defer ->
      currentController.setFilterValue(value)

  "submit form": (e) ->
    e.preventDefault()


Template.ironTableNav.helpers

  recordDisplayStart: ->
    getCurrentIronTableController()?.recordDisplayStart()

  recordDisplayStop: ->
    getCurrentIronTableController()?.recordDisplayStop()

  recordCount: ->
    getCurrentIronTableController()?.recordCount()

  nextPathClass: ->
    getCurrentIronTableController()?.nextPathClass()

  previousPathClass: ->
    getCurrentIronTableController()?.previousPathClass()

  recordsName: ->
    getCurrentIronTableController()?.getRecordsName()

  showPager: ->
    getCurrentIronTableController()?.recordCount() > getCurrentIronTableController()?.increment


Template.ironTableNav.events

  "click #previous": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.getPrevious()

  "click #next": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.getNext()


Template.ironTableRecords.events
  'mouseleave, mouseexit tr': ->
    console.log('mouse left row') if DEBUG
    Session.set("ironTableActiveRecordId", null)



Template.ironTableRow.onRendered ->
  $('[rel="tooltip"]')?.tooltip()
  #$('[rel="popover"]')?.popover()
  $('select').material_select()
  $('.modal-trigger').leanModal()


Template.ironTableRow.onDestroyed ->
  $('[rel="tooltip"]')?.tooltip('destroy')
  #$('[rel="popover"]')?.popover('destroy')
  $('[rel="tooltip"]')?.tooltip()
  #$('[rel="popover"]')?.popover()


Template.ironTableRow.helpers
  extraControls: ->
    if getCurrentIronTableController()?.extraControlsTemplate?
      Template[getCurrentIronTableController().extraControlsTemplate]

  templateRow: ->
    Template[@template]

  editRoute: ->
    getCurrentIronTableController()?.getEditRoute(@_id)

  rowLinkSkip: ->
    if @column.contenteditable or (@aLink? and not @rowLink)
      'rowlink-skip'

  contenteditable: ->
    @column.contenteditable and Template.parentData(1).editOk

  showJSON: ->
    getCurrentIronTableController()?.showJSON and @colData?[0]?.record?

  json: ->
    if @colData?[0]?.record?
      '<pre>' + JSON.stringify(@colData[0].record, null, 2) + '</pre>'


  ironPopupTemplate: ->
    """
    <div class="popover iron-table-popover" role="tooltip">
    <div class="arrow"></div>
    <h3 class="popover-title"></h3>
    <div class="popover-content"></div>
    </div>
    """

Template.ironTableRow.events

  "click .iron-table-value": (e, tmpl) ->
    console.log("Click", @, e.target) if DEBUG

  "input .iron-table-value": (e) ->
    console.log("html:'#{$(e.target).html()}'") if DEBUG
    newValue = $(e.target).html().trim()
    console.log("input value", newValue) if DEBUG
    if @column.type is 'number' and isNaN(newValue)
      console.log("input Nan")
      $(e.target).css('outline-color', 'red')
    else
      $(e.target).css('outline-color', '')


  "blur .iron-table-value": (e) ->
    if @column?.contenteditable? and @dataKey? and @record?._id?
      #$(e.target).prop('contenteditable', false)
      $(e.target).css('outline-color', '')
      newValue = $(e.target).html().trim()
      if @column.type is 'number'
        newValue = Number(newValue)
        console.log('number', newValue) if DEBUG
        if isNaN(newValue)
          console.log("bad number")
          $(e.target).html(@value)
          return
        #$(e.target).empty().html(newValue)
      if @value isnt newValue
        if not currentController = getCurrentIronTableController()
          Materialize.toast("Internal Error: Could not get controller", 3000, 'red')
        else
          $(e.target).html('')
          console.log("Submit Value Change", @dataKey, @value, '->', newValue) if DEBUG
          data = {}
          data[@dataKey] = newValue
          currentController.updateThisRecord(@record._id, data, 'inlineUpdate')


Template.ironTableHeaders.helpers
  headers: ->
    getCurrentIronTableController()?.headers()


Template.ironTableHeader.events
  "click .table-col-head": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.setSort(@dataKey)


Template.ironTableRecords.onRendered ->
  # ...


Template.ironTableRecords.helpers
  records: ->
    getCurrentIronTableController()?.recordsData()


Template.ironTableRow.onRendered ->
  $('[rel="tooltip"]').tooltip()
  #sizeCalc()


