

getCurrentIronTableController = ->
  if Router.current?()?.classID is "IronTableController"
    Router.current()
  #else
  #    console.log("Bad controller", Router.current?())
  #    null


#Template.ironTable.created = ->
#  console.log("ironTable created")


Template.ironTable.rendered = ->
  $('[rel="tooltip"]').tooltip()
  

Template.ironTable.helpers

  inabox: ->
    getCurrentIronTableController()?.inabox

  loading: ->
    loading = not getCurrentIronTableController()?.ready() and not getCurrentIronTableController()?.haveData()
    #console.log("loading", loading)
    loading

  haveData: ->
    #console.log("haveData Template")
    getCurrentIronTableController()?.haveData()


  # NOTE: Iron Router 7.1 and Meteor 8.2 not playing well together !?!?!?
  #       Moved from gettting in data to getting from controller in helpers
  
  showFilter: ->
    getCurrentIronTableController()?.showFilter

  recordsName: ->
    getCurrentIronTableController()?.getRecordsName()


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
    e.preventDefault()
    #e.stopImmediatePropagation()
    $('.iron-table-edit-record').tooltip('hide')

    if not currentController = getCurrentIronTableController()
      CoffeeAlerts.error("Internal Error: Could not get controller")
      false
    else
      currentController.editRecord(@_id)


Template.ironTableHeading.helpers
  
  tableTitle: ->
    getCurrentIronTableController()?.getTableTitle()

  doDownloadLink: ->
    getCurrentIronTableController()?.doDownloadLink

  showBackButton: ->
    getCurrentIronTableController()?.showBackButton

  showNewButton: ->
    getCurrentIronTableController()?.showNewButton

  newRecordPath: ->
    getCurrentIronTableController()?.newRecordPath
  
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


Template.ironTableRow.helpers
  extraControls: ->
    if currentController = getCurrentIronTableController()
      if currentController.extraControlsTemplate?
        Template[currentController.extraControlsTemplate] #(@)

  templateRow: ->
    Template[@template]


Template.ironTableRow.rendered = ->
  $('[rel="tooltip"]').tooltip()


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






