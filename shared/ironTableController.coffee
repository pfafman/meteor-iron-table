
class @IronTableController extends RouteController
    classID: 'IronTableController'

    increment       : 20
    sortColumn      : '_id'
    sortDirection   : 1
    
    template        : 'ironTable'
    rowTemplate     : 'ironTableRow'
    headerTemplate  : 'ironTableHeader'
    formTemplate    : 'ironTableForm'
    defaultSelect   : {}

    _subscriptionComplete = false
    
    constructor: ->
        #console.log("IronTableController constuct", @collection()._name)
        super
        @_sess("recordCount", "...")
        #@setupEditRoute()

    setupEditRoute: ->
        # Set Up Edit Path
        editRoutePath = @route.originalPath.replace(/\/[^\/]+$/ , '') + "/edit/:_id"
        editRouteName = @collection()._name + 'Edit'
        console.log("editPath", editRoutePath)

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

    editOk: (record) ->
        false
    deleteOk: (record) ->
        false

    before: ->
        if not @fetchingCount
            @fetchingCount = true
            Meteor.call 'ironTable_' +  @_collectionName() + '_recordCount', @select(), (error, number) =>
                @fetchingCount = false
                if not error and not @_sessEquals("recordCount", number)
                    @_sess("recordCount", number)
                else if error 
                    console.log('ironTable_' +  @_collectionName() + '_recordCount error:', error)

    load: ->
        #console.log("load", @_collectionName())

    unload: ->
        #console.log("unload", @_collectionName())
    
    _tableTitle: ->
        @tableTitle or @_collectionName()

    _collectionName: ->
        @collectionName or @collection()._name

    _recordName: ->
        @recordName or @collection().recordName or @collection()._name

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

    headers: =>
        rtn = []
        for colName, colObj of @_cols()
            if not (colObj.hide?() or colObj.hide)
                rtn.push 
                    key: colName
                    colName: colObj.header or colName
                    column: colObj
                    sort: colName is @sortColumn
                    desc: @sortDirection is -1
                    sortDirection: if colName is @sortColumn then -@sortDirection else @sortDirection
        rtn

    limit: ->
        @increment

    skipParamName: 'skip'

    skip: ->
        parseInt(@params[@skipParamName]) or 0
    
    sort: ->
        rtn = {}
        rtn[@sortColumn] = @sortDirection
        rtn

    waitOn: ->
        if @params.sort_on?
            @sortColumn = @params.sort_on
        if @params.sort_direction?
            @sortDirection = parseInt(@params.sort_direction)
        @subscribe()

    subscribe: ->
        @subscriptionId = Meteor.subscribe @_collectionName(), @select(), @sort(), @limit(), @skip(), =>
            @_subscriptionComplete = true

    unsubscribe: ->
        @_subscriptionId?.stop?()
        @_subscriptionId = null

    select: ->
        @defaultSelect

    valueFromRecord: (key, col, record) ->
        if record?
            if col?.value?
                value = col.value?(value, record) or col.value
            else if col?.dataKey?
                subElements = col.dataKey.split('.')
                value = record
                for subElement in subElements
                    value = value?[subElement]
                value
            else if record[key]?
                record[key]

    data: ->
        records = @collection()?.find(@select(),
            sort: @sort()
            limit: @limit()
        ).fetch()

        recordData = []
        for record in records
            colData = []
            for key, col of @_cols()
                dataKey = col.dataKey or key
                if not (col.hide?() or col.hide)
                    value = @valueFromRecord(key, col, record)
                    colData.push
                        value  : col.display?(value, record, @params) or value
                        aLink  : col.link?(value, record)
                        title  : col.title?(value, record) or col.title
                        column : col
                        key    : key
                    
            recordData.push
                colData: colData
                _id: record._id
                recordName: record[@_colToUseForName()]
                recordDisplayName: @_recordName() + ' ' + record[@_colToUseForName()]
                editOk: @collection().editOk?(record)
                deleteOk: @collection().deleteOk?(record)

        recordDisplayStop = @skip() + recordData.length
        
        theData =
            haveData: records? and (records.length > 0 or @_sess("recordCount") > 0)
            tableTitle: @_tableTitle()
            newRecordPath: @newRecordPath
            newRecordTitle: @newRecordTitle
            newRecordTooltip: @newRecordTooltip
            showBackButton: @showBackButton
            recordDisplayStart: @skip() + 1
            recordDisplayStop: recordDisplayStop
            recordName: @_recordName()
            records: recordData
            headers: @headers
            nextPath: @nextPath()
            nextPathClass: if (@skip() + @increment >= @_sess("recordCount")) then "disabled" else ""
            previousPath: @previousPath()
            previousPathClass: if (@skip() <= 0) then "disabled" else ""
            increment: @increment
            recordCount: @_sess("recordCount")

        _.extend(theData, @params)
        


    nextPath: ->
        params = _.clone(@select())
        params[@skipParamName] = @skip() + @increment
        @_pathFromParams(_.extend({}, @params, params))

    previousPath: ->
        params = _.clone(@select())
        params[@skipParamName] = @skip() - @increment
        @_pathFromParams(_.extend({}, @params, params))

    _pathFromParams: (params) ->
        Router.current().route.path params,
            query: 
                sort_on: @sortColumn
                sort_direction: @sortDirection

    removeRecord: (rec) ->
        console.log("removeRecord", @collection(), rec._id)
        
        name = rec.recordDisplayName

        @collection().remove rec._id, (error) ->
            if error
                console.log("Error deleting #{name}", error)
                CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
            else
                CoffeeAlerts.success("Deleted #{name}")
        
        #Meteor.call "ironTable_" + @collection()._name + "_remove", _id, (error) ->
        #    if error
        #        console.log("Error deleting #{name}", error)
        #        Meteor.defer ->
        #            CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
        #    else
        #        Meteor.defer ->
        #            CoffeeAlerts.success("Deleted #{name}")
        

    formData: (type, id = null) ->
        console.log("do form", @_cols())
        if type == 'edit' and id
            record = @collection().findOne(id)
        recordData = []
        for key, col of @_cols()
            dataKey = col.dataKey or key
            if col[type] or col["staticOn_#{type}"]
                col.displayType = col.type
                col.checkbox = false
                col.checked = false
                value = @valueFromRecord(key, col, record)
                if col.type is 'boolean'
                    col.displayType = 'checkbox'
                    col.checkbox = true
                    if record?[dataKey]?
                        if record[dataKey]
                            col.checked = true
                    else if col.default
                        col.checked = true
                else if value?
                    col.value = value
                else if col.default?
                    col.value = col.default
                
                if col["staticOn_#{type}"]
                    col.static = true
                    col.value = col.display?(record[dataKey], record) or record?[dataKey]
                    
                col.header = (col.header || key).capitalize()
                col.key = key

                recordData.push col
        columns: recordData

    saveRecord: (yesNo, rec) =>
        if yesNo
            @collection().update @_sess("currentRecordId"), 
                $set: rec
            , (error, effectedCount) =>
                console.log('update', error, effectedCount)
                if error
                    console.log("Error updating " + @_recordName(), error)
                    CoffeeAlerts.error("Error updating " + @_recordName() + " : #{error.reason}")
                else
                    CoffeeAlerts.success(@_recordName() + " updated")

    editRecord: (_id) =>
        console.log("editRecord", @_collectionName(), _id)
        @_sess("currentRecordId", _id)
        CoffeeModal.form(@formTemplate,  @formData('edit', _id), @saveRecord)
 


