
#
# Iron Table Controller
#


# Capitalize first letter in string
String::capitalize = ->
  @charAt(0).toUpperCase() + @slice(1)


class @IronTableController extends RouteController
  classID: 'IronTableController'

  increment       : 20
  sortColumn      : '_id'
  sortDirection   : 1
  
  template        : 'ironTable'
  rowTemplate     : 'ironTableRow'
  headerTemplate  : 'ironTableHeader'
  formTemplate    : 'ironTableForm'
  loadingTemplate : 'ironTableLoading'
  defaultSelect   : {}
  showFilter      : false

  _subscriptionComplete = false
  

  constructor: ->
    #console.log("IronTableController constuct", @collection()._name)
    super
    @reset()
    #@setupEditRoute()


  reset: ->
    #console.log("reset")
    @_sess("recordCount", "...")
    @_sessDefault('skip', 0)
    @_sessDefault('sortColumn', @sortColumn)
    @_sessDefault('sortDirection', @sortDirection)
    @_sessDefault('filterColumn', null)
    @_sessDefault('filterValue', '')
    @fetchingCount = null


  fetchRecordCount: ->
    if not @fetchingCount
      @fetchingCount = true
      Meteor.call 'ironTable_' + @_collectionName() + '_recordCount', @_select(), (error, number) =>
        @fetchingCount = false
        if not error and not @_sessEquals("recordCount", number)
          @_sess("recordCount", number)
        else if error 
          console.log('ironTable_' +  @_collectionName() + '_recordCount error:', error)


  downloadRecords: (callback) ->
    fields = {}
    if @collection().downloadFields?
      fields = @collection().downloadFields
    else
      for key, col of @_cols()
        dataKey = col.dataKey or key
        fields[dataKey] = 1

    Meteor.call "ironTable_" + @_collectionName() + "_getCSV", @_select(), fields, callback


  setupEditRoute: ->
    # Set Up Edit Path
    editRoutePath = @route.originalPath.replace(/\/[^\/]+$/ , '') + "/edit/:_id"
    editRouteName = @collection()._name + 'Edit'

    Router.map ->
      @route editRouteName,
        path: editRoutePath
  

  _sess: (id, value) ->
    key = "_ironTable_" + @_collectionName() + id
    if value?
      Session.set(key, value)
    else
      Session.get(key)

  _sessEquals: (id, value) ->
    Session.equals("_ironTable_" + @_collectionName() + id, value)

  _sessNull: (id) ->
    Session.set("_ironTable_" + @_collectionName() + id, null)

  _sessDefault: (id, value) ->
    Session.setDefault("_ironTable_" + @_collectionName() + id, value)

  #editOk: (record) ->
  #    false
  
  #deleteOk: (record) ->
  #    false

  #onBeforeAction: (pause) ->
  #    console.log("onBeforeAction")


  onRun: ->
    #console.log("onRun", @_collectionName())
    @reset()
      

  onStop: ->
    @unsubscribe()
    @reset()
  

  getTableTitle: ->
    @tableTitle or @_collectionName()

  _collectionName: ->
    @collectionName or @collection()._name

  _recordName: ->
    @recordName or @collection().recordName or @collection()._name

  _recordsName: ->
    @recordsName or @collection().recordsName or @_recordName()+'s'

  _colToUseForName: ->
    @colToUseForName or @collection().colToUseForName or '_id'


  _cols: ->
    theCol = @cols or @collection()?.schema
    if theCol instanceof Array
      colObj = {}
      for col in theCol
        colObj[col] = {}
    else
      colObj = theCol
    colObj


  filterHeaders: =>
    rtn = []
    for key, col of @_cols()
      #if not (col.hide?() or col.hide)
      dataKey = col.dataKey or key
      if col.canFilterOn? and not col.hide?()
        canFilterOn = col.canFilterOn
      else
        canFilterOn = false
      rtn.push 
        key: key
        dataKey: dataKey
        colName: col.header or key
        column: col
        filterOnThisCol: dataKey is @_sess('filterColumn')
        canFilterOn: canFilterOn
        hide: col.hide?()
    rtn


  headers: =>
    rtn = []
    for key, col of @_cols()
      #if not (col.hide?() or col.hide)
      dataKey = col.dataKey or key
      if col.canFilterOn? and not col.hide?()
        canFilterOn = col.canFilterOn
      else
        canFilterOn = false
      rtn.push 
        key: key
        dataKey: dataKey
        colName: col.header or key
        column: col
        noSort: col.noSort
        sort: dataKey is @_sess('sortColumn')
        desc: @_sess('sortDirection') is -1
        #sortDirection: if dataKey is @_sess('sortColumn') then -@sortDirection else @sortDirection
        filterOnThisCol: dataKey is @_sess('filterColumn')
        canFilterOn: canFilterOn
        hide: col.hide?()
    rtn


  limit: ->
    @increment


  skip: ->
    @_sess('skip')
      
  
  setSort: (dataKey) ->
    if dataKey is @_sess('sortColumn')
      @_sess('sortDirection',  -@_sess('sortDirection'))
      @_sess('skip', 0)
    else
      @_sess('sortColumn', dataKey)
      @_sess('sortDirection', @sortDirection)
      @_sess('skip', 0)

  
  sort: ->
    rtn = {}
    rtn[@_sess('sortColumn')] = @_sess('sortDirection')
    rtn

  
  waitOn: ->
    @subscribe()


  publicationName: ->
    @collection().publicationName?() or 'ironTable_publish_'+ @_collectionName()

  
  subscribe: ->
    @_subscriptionId = Meteor.subscribe(@publicationName(), @_select(), @sort(), @limit(), @skip())

  
  unsubscribe: ->
    @_subscriptionId?.stop?()
    @_subscriptionId = null

  
  _select: ->
    #console.log("_select")
    select = _.extend({}, @select())
    filterColumn = @_sess('filterColumn')
    filterValue = @_sess('filterValue')
    col = @_cols()[filterColumn]
    if filterColumn and filterColumn isnt "_none_" and filterValue and col and filterValue isnt ''
      dataKey = col.dataKey or filterColumn
      select[dataKey] = 
        $regex: ".*#{filterValue}.*"
        $options: 'i'
    select

  
  select: ->
    @defaultSelect
  

  valueFromRecord: (key, col, record) ->
    if record?
      if col?.valueFunc?
        value = col.valueFunc?(record[key], record)
      else if col?.dataKey?
        subElements = col.dataKey.split('.')
        value = record
        for subElement in subElements
          value = value?[subElement]
        value
      else if record[key]?
        record[key]

  
  records: ->
    @collection()?.find @_select(),
      sort: @sort()
      limit: @limit()
    .fetch()

  
  recordsData: ->
    recordsData = []
    cols = @_cols()
    for record in @records()
      colData = []
      for key, col of cols
        dataKey = col.dataKey or key
        if not col.hide?()
          value = @valueFromRecord(key, col, record)
          colData.push
            template     : col.template
            value        : col.display?(value, record, @params) or value
            aLink        : col.link?(value, record)
            title        : col.title?(value, record) or col.title
            column       : col
            dataKey      : dataKey

              
      recordsData.push
        colData: colData
        _id: record._id
        recordName: record[@_colToUseForName()]
        recordDisplayName: @_recordName() + ' ' + record[@_colToUseForName()]
        editOk: @collection().editOk?(record)
        deleteOk: @collection().deleteOk?(record)
        #extraControls: @extraControls?(record)
    recordsData


  haveData: ->
    @recordCount() > 0 or @records().length > 0
  

  recordDisplayStop: ->
    @skip() + @records().length


  recordDisplayStart: ->
    @skip() + 1


  recordCount: ->
    if @_sess("recordCount") is '...'
      @fetchRecordCount()
    @_sess("recordCount")

  
  data: ->
    #console.log("ironTableController data")
    theData =
      increment: @increment

      # NOTE: Iron Router 7.1 and Meteor 8.2 not playing well together !?!?!?
      #       Moved from gettting in data to getting from controller in helpers

      #newRecordPath: @newRecordPath
      #newRecordTitle: @newRecordTitle
      #newRecordTooltip: @newRecordTooltip
      #showBackButton: @showBackButton
      #showFilter: @showFilter
      #recordName: @_recordName()
      #recordsName: @_recordsName()
      #doDownloadLink: @doDownloadLink
      #headers: @headers()
      #records: @recordsData()

    _.extend(theData, @params)
      

  getRecordsName: ->
    @_recordsName()


  getRecordName: ->
    @_recordName()


  getNext: ->
    @_sess('skip', @skip() + @increment)


  nextPathClass: ->
    if (@skip() + @increment >= @recordCount()) then "disabled" else ""


  getPrevious: ->
    @_sess('skip', Math.max(@skip() - @increment, 0))


  previousPathClass: ->
    if (@skip() <= 0) then "disabled" else ""
 

  removeRecord: (rec) ->
    name = rec.recordDisplayName
    @collection().remove rec._id, (error) =>
      if error
        console.log("Error deleting #{name}", error)
        CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
      else
        CoffeeAlerts.success("Deleted #{name}")
      @fetchRecordCount()


  checkRequiredFields: (rec) ->
    for key, col of @_cols()
      dataKey = col.dataKey or key
      if col.required and (not rec[dataKey]? or rec[dataKey] is '')
        col.header = (col.header || key).capitalize()
        CoffeeAlerts.error("#{col.header} is required")
        return false
    true


  formData: (type, id = null) ->

    if type is 'edit' and id?
      record = @collection().findOne(id)
    else
      record = null
    recordData = []
    
    for key, col of @_cols()
      dataKey = col.dataKey or key
      localCol = _.clone(col)
      if col[type]?() or (col[type] is true) or col["staticOn_#{type}"]
        localCol.displayType = col.type
        localCol.checkbox = false
        localCol.checked = false
        value = @valueFromRecord(key, col, record)
        if col.type is 'boolean'
          localCol.displayType = 'checkbox'
          localCol.checkbox = true
          if record?[dataKey]?
            if record[dataKey]
              localCol.checked = true
          else if col.default
            localCol.checked = true
        else if value?
          localCol.value = value
        else if col.default?
          localCol.value = col.default
        
        if col["staticOn_#{type}"]
          localCol.static = true
          localCol.value = value
            
        localCol.header = (col.header || key).capitalize()
        localCol.key = key
        localCol.dataKey = dataKey

        recordData.push localCol
    columns: recordData


  editRecord: (_id) ->
    @_sess("currentRecordId", _id)
    CoffeeModal.form(@formTemplate, @formData('edit', _id), @saveRecord, 'Edit ' + @_recordName().capitalize())


  saveRecord: (yesNo, rec) =>
    if yesNo
      # if @collection.editOk(rec) # Do we need to check again ???
      @collection().update @_sess("currentRecordId"), 
        $set: rec
      , (error, effectedCount) =>
        if error
          console.log("Error updating " + @_recordName(), error)
          CoffeeAlerts.error("Error updating " + @_recordName() + " : #{error.reason}")
        else
          CoffeeAlerts.success(@_recordName() + " updated")
          @fetchRecordCount()

  newRecord: ->
    CoffeeModal.form(@formTemplate, @formData('insert'), @saveNewRecord, 'New ' + @_recordName().capitalize())


  saveNewRecord: (yesNo, rec) =>
    if yesNo
      if @collection().insertOk(rec) and @checkRequiredFields(rec)
        if @collection.methodOnInsert
          Meteor.call @collection.methodOnInsert, rec, (error, number) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              CoffeeAlerts.error("Error saving " + @_recordName() + " : #{error.reason}")
            else
              CoffeeAlerts.success(@_recordName() + " created")
              @fetchRecordCount()
        else
          @collection().insert rec, (error, effectedCount) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              CoffeeAlerts.error("Error saving " + @_recordName() + " : #{error.reason}")
            else
              CoffeeAlerts.success(@_recordName() + " created")
              @fetchRecordCount()
      else
        CoffeeAlerts.error("Error could not save new " + @_recordName())


  setFilterColumn: (col) ->
    if @_sess('filterColumn') isnt col
      @_sess('filterColumn', col)
      @_sess('filterValue', '')
      @_sess('skip', 0)
      @fetchRecordCount()


  setFilterValue: (value) ->
    if @_sess('filterValue') isnt value
      @_sess('filterValue', value)
      @_sess('skip', 0)
      @fetchRecordCount()


  getFilterValue: ->
    @_sess('filterValue')

