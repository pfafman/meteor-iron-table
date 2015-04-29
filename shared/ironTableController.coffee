
#
# Iron Table Controller
#

DEBUG = false

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
  cursor          : null
  
  _subscriptionComplete: false


  constructor: ->
    super
    @reset()


  reset: ->
    #console.log("reset")
    if Meteor.isClient
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
    console.log("setup edit route", @editRouteName) if DEBUG
    Router.map ->
      @route editRouteName,
        path: editRoutePath
        waitOn: ->
          Meteor.subscribe(@collection()._name + 'OneRecord', @params._id)
        data: ->
          data = @collection()?.findOne
            _id: @params._id
          data.returnPath = @route.originalPath


  getEditRoute: (id) =>
    @editRecordRoute
    #console.log("getEditRoute", @editRecordRoute, id)
    #if @editRecordRoute? and Router.routes[@editRecordRoute]?
    #  Router.go
    #    _id: id


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
    @next()


  onStop: ->
    $('[rel="tooltip"]')?.tooltip('destroy')
    $('[rel="popover"]')?.popover('destroy')
    @unsubscribe()
    @reset()

  getTableTitle: ->
    if not @doNotShowTitle or @showTitleLargeOnly
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
      colName = col.header or key
      if T9n?
        colName = T9n.get(colName)
      rtn.push
        key: key
        dataKey: dataKey
        colName: colName
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
      colName = col.header or key
      if T9n?
        colName = T9n.get(colName)
      rtn.push
        key: key
        dataKey: dataKey
        colName: colName
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


  subscriptions: ->   # was waitOn
    #console.log('subscriptions')
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
    if filterColumn and filterColumn isnt "_none_"
      dataKey = col.dataKey or col.sortKey or filterColumn
      if col.type is 'boolean'
        if filterValue
          select[dataKey] = filterValue
        else
          select[dataKey] =
            $ne: true
      else if filterValue and col and filterValue isnt ''
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
    @cursor = @collection()?.find @_select(),
      sort: @sort()
      limit: @limit()
    @afterCursor?(@cursor)
    @cursor.fetch()


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

  docsReady: ->
    if @collection().publishCounts
      @recordCount()?
    else
      @ready()

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

    _.extend(theData, @params)


  getRecordsName: ->
    @_recordsName()


  getRecordName: ->
    @_recordName()


  getNext: ->
    if (@skip() + @increment < @recordCount())
      @_sess('skip', @skip() + @increment)


  nextPathClass: ->
    if (@skip() + @increment >= @recordCount())
      "disabled"
    #else 
    #  "waves-effect "


  getPrevious: ->
    @_sess('skip', Math.max(@skip() - @increment, 0))


  previousPathClass: ->
    if (@skip() <= 0)
      "disabled"
    #else 
    #  "waves-effect"


  removeRecord: (rec) ->
    name = rec.recordDisplayName
    if @collection().methodOnRemove
      Meteor.call @collection().methodOnRemove, rec._id, (error) =>
        if error
          console.log("Error deleting #{name}", error)
          Materialize.toast("Error deleting #{name}: #{error.reason}", 3000, 'red')
        else
          Materialize.toast("Deleted #{name}", 3000, 'green')
        @fetchRecordCount()
    else
      @collection().remove rec._id, (error) =>
        if error
          console.log("Error deleting #{name}", error)
          Materialize.toast("Error deleting #{name}: #{error.reason}", 3000, 'red')
        else
          Materialize.toast("Deleted #{name}", 3000, 'green')
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

    if @extraFormData?
      _.extend(record, @extraFormData(type))

    if @formTemplate is 'ironTableForm'
      recordData = []

      for key, col of @_cols()
        dataKey = col.dataKey or col.sortKey or key
        localCol = _.clone(col)
        if col[type]?(record) or (col[type] is true) or col["staticOn_#{type}"] or col["hiddenOn_#{type}"]
          if col["hiddenOn_#{type}"]
            col.type = 'hidden'
          if not col.type?
            col.type = 'text'
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

          localCol.realValue = value

          if col["staticOn_#{type}"]
            localCol.static = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          if col["hiddenOn_#{type}"]
            localCol.hidden = true
            localCol.value = value
            if col?.valueFunc?
              localCol.realValue = record[key]

          localCol.header = (col.header or key).capitalize()
          localCol.key = key
          localCol.dataKey = dataKey

          recordData.push localCol
      columns: recordData
    else
      record


  editRecordTitle: ->
    'Edit ' + @_recordName().capitalize()


  editRecord: (_id) ->
    @_sess("currentRecordId", _id)
    MaterializeModal.form
      bodyTemplate: @formTemplate
      title: @editRecordTitle()
      columns: @formData('edit', _id).columns
      callback: @updateRecord
      fullscreen: Meteor.isCordova
      fixedFooter: true
      

  updateRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo
      rec = {} unless rec
      rec._id = @_sess("currentRecordId") unless rec._id?
      if @collection().editOk(rec)
        @updateThisRecord(@_sess("currentRecordId"), rec)


  updateThisRecord: (recId, rec, type="update") =>
    console.log("updateThisRecord", recId, rec)
    if @checkFields(rec, type)
      if @collection().methodOnUpdate
        Meteor.call @collection().methodOnUpdate, recId, rec, (error) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            Materialize.toast("Error updating " + @_recordName() + " : #{error.reason}", 3000, 'red')
          else if type isnt "inlineUpdate"
            Materialize.toast(@_recordName() + " saved", 3000, 'green')
            @fetchRecordCount()
      else
        delete rec._id
        @collection().update recId,
          $set: rec
        , (error, effectedCount) =>
          if error
            console.log("Error updating " + @_recordName(), error)
            Materialize.toast("Error updating " + @_recordName() + " : #{error.reason}", 3000, 'red')
          else
            if type isnt "inlineUpdate"
              Materialize.toast(@_recordName() + " updated", 3000, 'green')
            @fetchRecordCount()
    else
      Materialize.toast("Error could not update " + @_recordName() + " " + @errorMessage, 3000, 'red')


  newRecord: ->
    if @newRecordPath?
      Router.go(@newRecordPath)
    else
      MaterializeModal.form
        bodyTemplate: @formTemplate
        title: 'New ' + @_recordName().capitalize()
        columns: @formData('insert').columns
        callback: @insertRecord
        fullscreen: Meteor.isCordova
        fixedFooter: true

  insertRecord: (yesNo, rec) =>
    @errorMessage = ''
    if yesNo
      if @collection().insertOk(rec) and @checkFields(rec, 'insert')
        if @collection().methodOnInsert
          Meteor.call @collection().methodOnInsert, rec, (error) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              Materialize.toast("Error saving " + @_recordName() + " : #{error.reason}", 3000, 'red')
            else
              Materialize.toast(@_recordName() + " created", 3000, 'green')
              @fetchRecordCount()
              @newRecordCallback?(rec)
        else
          @collection().insert rec, (error, effectedCount) =>
            if error
              console.log("Error saving " + @_recordName(), error)
              Materialize.toast("Error saving " + @_recordName() + " : #{error.reason}", 3000, 'red')
            else
              Materialize.toast(@_recordName() + " created", 3000, 'green')
              @fetchRecordCount()
              @newRecordCallback?(effectedCount)
      else
        Materialize.toast("Error could not save " + @_recordName() + " " + @errorMessage, 3000, 'red')


  setFilterColumn: (col) ->
    if @_sess('filterColumn') isnt col
      @_sess('filterColumn', col)
      @_sess('filterValue', '')
      @_sess('skip', 0)
      @fetchRecordCount()


  setFilterValue: (value) ->
    console.log("setFilterValue", value) if DEBUG
    
    if @_sess('filterValue') isnt value
      @_sess('filterValue', value)
      @_sess('skip', 0)
      @fetchRecordCount()


  getFilterValue: ->
    @_sess('filterValue')


  getSelectedFilterType: ->
    filterColumn = @_sess('filterColumn')
    if filterColumn?
      switch (@_cols()?[filterColumn]?.type)
        when 'boolean'
          'checkbox'
        else
          'text'
    else
      'text'




