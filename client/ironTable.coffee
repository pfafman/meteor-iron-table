
DEBUG = false

getCurrentIronTableController = ->
  if Router.current?()?.classID is "IronTableController"
    Router.current()
  #else
  #    console.log("Bad controller", Router.current?())
  #    null


#Template.ironTable.created = ->
#  console.log("ironTable created")


Template.ironTable.rendered = ->
  $('[rel="tooltip"]').tooltip('destroy')
  $('[rel="popover"]').popover('destroy')
  $('[rel="tooltip"]').tooltip()
  $('[rel="popover"]').popover()

Template.ironTable.destroyed = ->
  $('[rel="tooltip"]').tooltip('destroy')
  $('[rel="popover"]').popover('destroy')

Template.ironTable.helpers

  inabox: ->
    getCurrentIronTableController()?.inabox

  loading: ->
    not getCurrentIronTableController()?.ready() and not getCurrentIronTableController()?.haveData()

  haveData: ->
    getCurrentIronTableController()?.haveData()


  # NOTE: Iron Router 7.1 and Meteor 8.2 not playing well together !?!?!?
  #       Moved from gettting in data to getting from controller in helpers
  #       TODO: Check if this is better in Meteor 0.9

  showFilter: ->
    getCurrentIronTableController()?.showFilter

  recordsName: ->
    getCurrentIronTableController()?.getRecordsName()

  rowLink: ->
    if getCurrentIronTableController()?.doRowLink()
      "rowlink"

  dataLink: ->
    if getCurrentIronTableController()?.doRowLink()
      "row"


Template.ironTable.events

  "click .iron-table-delete-record": (e, tmpl) ->
    e.preventDefault()
    #e.stopImmediatePropagation()
    $('.iron-table-delete-record').tooltip('hide')

    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      return false

    CoffeeModal.confirm "Are you sure you want to delete #{@recordDisplayName}?", (yesNo) =>
      if yesNo
        currentController.removeRecord(@)
    , "Delete"

  "click .iron-table-edit-record": (e, tmpl) ->
    currentController = getCurrentIronTableController()
    if not currentController?.getEditRoute(@_id)?
      e.preventDefault()
      #e.stopImmediatePropagation()
      $('.iron-table-edit-record').tooltip('hide')

      if not currentController
        CoffeeAlerts.error("Internal Error: Could not get controller")
        false
      else
        currentController.editRecord(@_id)


Template.ironTableHeading.helpers

  tableTitle: ->
    getCurrentIronTableController()?.getTableTitle()

  subTitle: ->
    getCurrentIronTableController()?.getSubTitle()

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


Template.ironTableHeading.events
  "click #iron-table-new-record": (e, tmpl) ->
    e.preventDefault()
    #e.stopImmediatePropagation()
    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      false
    else
      currentController.newRecord()


  "click #download-link": (e, tmpl) ->
    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      return false

    filename = @tableTitle + '.csv'
    currentController.downloadRecords (error, csv) ->
      if error
        CoffeeAlerts.error("Error getting CSV to download")
        console.log("Error getting CSV", error)
      else if csv
        console.log("Doing saveAs for CSV")
        blob = new Blob [csv],
          type: "text/csv"
        saveAs?(blob, filename)
        CoffeeAlerts.success("Records Downloaded")
      else
        CoffeeAlerts.alert("No data to download")


#Template.ironTableFilter.created = ->
#  console.log("ironTableFilter created")


#Template.ironTableFilter.rendered = ->
#  console.log("ironTableFilter rendered")


Template.ironTableFilter.helpers
  headers: ->
    getCurrentIronTableController()?.filterHeaders()

  filterValue: ->
    getCurrentIronTableController()?.getFilterValue()


Template.ironTableFilter.events

  "change #filter-column": (e, tmpl) ->
    #e.preventDefault()
    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      return false

    currentController.setFilterColumn(e.target.value)

  "keyup, change #filter-value": (e, tmpl) ->
    #e.preventDefault()
    #console.log("filter-value", e.target.value, $("#filter-value").val())
    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      return false
    Meteor.defer ->
      currentController.setFilterValue(e.target.value)

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


Template.ironTableNav.events

  "click #previous": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.getPrevious()

  "click #next": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.getNext()


Template.ironTableRecords.events
  'mouseleave, mouseexit tr': ->
    if DEBUG
      console.log('mouse left row')
    Session.set("ironTableActiveRecordId", null)


Template.ironTableRow.rendered = ->
  $('[rel="tooltip"]').tooltip()
  $('[rel="popover"]').popover()


Template.ironTableRow.destroyed = ->
  $('[rel="tooltip"]').tooltip('destroy')
  $('[rel="popover"]').popover('destroy')


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
    if DEBUG
      console.log("Click", @, e.target)

  "input .iron-table-value": (e) ->
    if DEBUG
      console.log("html:'#{$(e.target).html()}'")
    newValue = $(e.target).html().trim()
    if DEBUG
      console.log("input value", newValue)
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
        if DEBUG
          console.log('number', newValue)
        if isNaN(newValue)
          console.log("bad number")
          $(e.target).html(@value)
          return
        #$(e.target).empty().html(newValue)
      if @value isnt newValue
        if not currentController = getCurrentIronTableController()
          CoffeeAlerts.error("Internal Error: Could not get controller")
        else
          $(e.target).html('')
          console.log("Submit Value Change", @dataKey, @value, '->', newValue)
          data = {}
          data[@dataKey] = newValue
          currentController.updateThisRecord(@record._id, data, 'inlineUpdate')


Template.ironTableHeader.rendered = ->
  $('[rel="tooltip"]').tooltip()


Template.ironTableHeaders.helpers
  headers: ->
    getCurrentIronTableController()?.headers()


Template.ironTableHeader.events
  "click .table-col-head": (e, tmpl) ->
    e.preventDefault()
    getCurrentIronTableController()?.setSort(@dataKey)


Template.ironTableRecords.helpers
  records: ->
    getCurrentIronTableController()?.recordsData()
