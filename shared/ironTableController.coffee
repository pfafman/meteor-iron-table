
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
  errorMessage    : ''

  _subscriptionComplete = false


  constructor: ->
    super
    @reset()


  reset: ->
    #console.log("reset")
    @_sess("recordCount", "...")
    @_sessDefault('skip', 0)
    @_sessDefault('sortColumn', @sortColumn)
    @_sessDefault('sortDirection', @sortDirection)
    @_sessDefault('filterColumn', null)
    @_sessDefault('filterValue', '')
    @fetchingCount = null
    @errorMessage = ''


  fetchRecordCount: ->
    if not @collection().publishCounts and not @fetchingCount
      @fetchingCount = true
      # TODO: Set a timeout ?!?!
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
        dataKey = col.dataKey or col.sortKey or key
        fields[dataKey] = 1

    Meteor.call "ironTable_" + @_collectionName() + "_getCSV", @_select(), fields, callback


  # Pain in the ass to set up....  Not using
  setupEditRoute: ->
    # Set Up Edit Path
    editRoutePath = @route.originalPath.replace(/\/[^\/]+$/ , '') + "/edit/:_id"
    editRouteName = 'edit' + @collection()._name.capitalize()
    @editRouteName = editRouteName
    console.log("setup edit route", @editRouteName)
    Router.map ->
      @route editRouteName,
        path: editRoutePath
        wait: ->
          Meteor.subscribe(@collection()._name + 'OneRecord', @params._id)
        data: ->
          data = @collection()?.findOne
            _id: @params._id
          data.returnPath = @route.originalPath


  getEditRoute: (id) =>
    if @editRecordRoute?
      Router.routes[@editRecordRoute].path
        _id: id


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

  getSubTitle: ->
    @subTitle

  _collectionName: ->
    @collectionName or @collection()._name

  _recordName: ->
    @recordName or @collection().recordName or @collection()._name

  _recordsName: ->
    @recordsName or @collection().recordsName or @_recordName()+'s'

  _colToUseForName: ->
    @colToUseForName or @collection().colToUseForName or '_id'

  doRowLink: ->
    @collection()?.doRowLink

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
      dataKey = col.dataKey or col.sortKey or key
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
      dataKey = col.dataKey or col.sortKey or key
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
    #console.log('waitOn')
    @subscribe()


  publicationName: ->
    @collection().publicationName?() or 'ironTable_publish_'+ @_collectionName()


  subscribe: ->
    @_subscriptionId = Meteor.subscribe(@publicationName(), @_select(), @sort(), @limit(), @skip())


  unsubscribe: ->
    @_subscriptionId?.stop?()
    @_subscriptionId = null


  _select: ->
    select = _.extend({}, @select())
    filterColumn = @_sess('filterColumn')
    filterValue = @_sess('filterValue')
    col = @_cols()[filterColumn]
    if filterColumn and filterColumn isnt "_none_" and filterValue and col and filterValue isnt ''
      dataKey = col.dataKey or col.sortKey or filterColumn
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
        dataKey = col.dataKey or col.sortKey or key
        if not col.hide?()
          value = @valueFromRecord(key, col, record)
          if col.display?
            value = col.display(value, record, @params)
          if col.type is 'boolean' and not col.template?
            col.template = 'ironTableCheckbox'
          else if col.type is 'select' and not col.template?
            col.template = 'ironTableSelect'
          colData.push
            type         : col.type
            template     : col.template
            record       : record  # Link to full record if we need it
            value        : value
            aLink        : col.link?(value, record)
            title        : col.title?(value, record) or col.title
            column       : col
            dataKey      : dataKey
            select       : col.select


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
    @recordCount() > 0 or (not @collection().publishCounts and @records().length > 0)


  recordDisplayStop: ->
    @skip() + @records().length


  recordDisplayStart: ->
    @skip() + 1


  recordCount: ->
    if @collection().publishCounts
      Counts.get(@collection().countName())
    else
      if @_sess("recordCount") is '...'
        @fetchRecordCount()
      @_sess("recordCount")


  data: ->
  #  console.log("ironTableController data")
  #  {}
    theData =
      increment: @increment

      # NOTE: Iron Router 7.1 and Meteor 8.2+ not playing well together !?!?!?
      #       Moved from gettting in data to getting from controller in helpers

      #tableTitle: @getTableTitle()
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
      #@fetchRecordCount()
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
    if @collection().methodOnRemove
      Meteor.call @collection().methodOnRemove, rec._id, (error) =>
        if error
          console.log("Error deleting #{name}", error)
          CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
        else
          CoffeeAlerts.success("Deleted #{name}")
        @fetchRecordCount()
    else
      @collection().remove rec._id, (error) =>
        if error
          console.log("Error deleting #{name}", error)
          CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
        else
          CoffeeAlerts.success("Deleted #{name}")
        @fetchRecordCount()


  checkFields: (rec, type="insert") ->
    @errorMessage = ''
    for key, col of @_cols()
      try
        dataKey = col.dataKey or col.sortKey or key
        if type isnt "inlineUpdate" and col.required and (not rec[dataKey]? or rec[dataKey] is '')
          col.header = (col.header || key).capitalize()
          @errorMessage = ':' + "#{col.header} is required"
          return false
        else if type is 'insert' and col.onInsert?
          rec[dataKey] = col.onInsert()
        else if type in ['update', 'inlineUpdate'] and col.onUpdate?
          rec[dataKey] = col.onUpdate()
      catch error
        @errorMessage = ':' + error.reason or error
        return false
    true


  formData: (type, id = null) ->

    if type is 'edit' and id?
      record = @collection().findOne(id)
    else
      record = null


    if @formTemplate is 'ironTableForm'
      recordData = []

      for key, col of @_cols()
        dataKey = col.dataKey or col.sortKey or key
        localCol = _.clone(col)
        if col[type]?(record) or (col[type] is true) or col["staticOn_#{type}"]
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
    else
      record



  editRecord: (_id) ->
    @_sess("currentRecordId", _id)
    CoffeeModal.form(@formTemplate, @formData('edit', _id), @updateRecord, 'Edit ' + @_recordName().capitalize())


  updateRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo and @collection().editOk(rec)
      @updateThisRecord(@_sess("currentRecordId"), rec)


  updateThisRecord: (recId, rec, type="update") =>
    if @checkFields(rec, type)
      if @collection().methodOnUpdate
        Meteor.call @collection().methodOnUpdate, recId, rec, (error) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            CoffeeAlerts.error("Error updating " + @_recordName() + " : #{error.reason}")
          else if type isnt "inlineUpdate"
            CoffeeAlerts.success(@_recordName() + " saved")
            @fetchRecordCount()
      else
        @collection().update recId,
          $set: rec
        , (error, effectedCount) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            CoffeeAlerts.error("Error updating " + @_recordName() + " : #{error.reason}")
          else
            if type isnt "inlineUpdate"
              CoffeeAlerts.success(@_recordName() + " updated")
            @fetchRecordCount()
    else
      CoffeeAlerts.error("Error could not update " + @_recordName() + " " + @errorMessage)


  newRecord: ->
    CoffeeModal.form(@formTemplate, @formData('insert'), @insertRecord, 'New ' + @_recordName().capitalize())


  insertRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo
      if @collection().insertOk(rec) and @checkFields(rec, 'insert')
        if @collection().methodOnInsert
          Meteor.call @collection().methodOnInsert, rec, (error) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              CoffeeAlerts.error("Error saving " + @_recordName() + " : #{error.reason}")
            else
              CoffeeAlerts.success(@_recordName() + " created")
              @fetchRecordCount()
              @newRecordCallback?(rec)
        else
          @collection().insert rec, (error, effectedCount) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              CoffeeAlerts.error("Error saving " + @_recordName() + " : #{error.reason}")
            else
              CoffeeAlerts.success(@_recordName() + " created")
              @fetchRecordCount()
              @newRecordCallback?(effectedCount)
      else
        CoffeeAlerts.error("Error could not save " + @_recordName() + " " + @errorMessage)


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
