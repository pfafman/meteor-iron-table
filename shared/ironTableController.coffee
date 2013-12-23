
class @IronTableController extends RouteController

    increment       : 20
    sortColumn      : '_id'
    sortDirection   : 1
    
    template        : 'ironTable'
    rowTemplate     : 'ironTableRow'
    headerTemplate  : 'ironTableHeader'

    constructor: ->
        console.log("IronTableController constuct", @collection()._name)
        super
        
        #@setupEditRoute()

        Meteor.defer =>
            @setupEvents()

        @_sess("recordCount", "...")

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
            Meteor.call 'ironTable_' +  @_collectionName() + '_recordCount', (error, number) =>
                @fetchingCount = false
                if not error and not @_sessEquals("recordCount", number)
                    @_sess("recordCount", number)
                else if error 
                    console.log('ironTable_' +  @_collectionName() + '_recordCount error:', error)

    unload: ->
        console.log("unload")
    
    _tableTitle: ->
        @tableTitle or @_collectionName() #.capitalize()

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
            if not colObj.hide
                rtn.push 
                    colName: colObj.header or colName
                    col: colObj
                    sort: colName is @sortColumn
                    desc: @sortDirection is -1
                    sortDirection: if colName is @sortColumn then -@sortDirection else @sortDirection
        rtn

    limit: ->
        @increment

    skip: ->
        parseInt(@params.skip) or 0
    
    sort: ->
        rtn = {}
        rtn[@sortColumn] = @sortDirection
        rtn

    waitOn: ->
        if @params.sort_on?
            @sortColumn = @params.sort_on
        if @params.sort_direction?
            @sortDirection = parseInt(@params.sort_direction)

        Meteor.subscribe @_collectionName(), @sort(), @limit(), @skip()
    
    data: ->
        records = @collection().find( {},
            sort: @sort()
            limit: @limit()
        ).fetch()

        recordData = []
        for record in records
            colData = []
            for col, colObj of @_cols()
                if not colObj.hide
                    colData.push
                        value : colObj.func?(record) or record[col]
                        aLink : colObj.link?(record)
                        title : colObj.title?(record) or colObj.title
                    
            recordData.push
                colData: colData
                _id: record._id
                recordDisplayName: @_recordName() + ' ' + record[@_colToUseForName()]
                editOk: @collection().editOk(record)
                deleteOk: @collection().deleteOk(record)

        theData =
            tableTitle: @_tableTitle()
            recordDisplayStart: @skip() + 1
            recordDisplayStop: @skip() + @increment
            recordName: @_recordName()
            records: recordData
            headers: @headers
            nextPath: @nextPath()
            nextPathClass: if (@skip() + @increment >= @_sess("recordCount")) then "disabled" else ""
            previousPath: @previousPath()
            previousPathClass: if (@skip() <= 0) then "disabled" else ""
            increment: @increment
            recordCount: @_sess("recordCount")


    nextPath: ->
        Router.current().route.path
            skip: @skip() + @increment
        ,
            query: 
                sort_on: @sortColumn
                sort_direction: @sortDirection

    previousPath: ->
        Router.current().route.path
            skip: @skip() - @increment
        ,
            query: 
                sort_on: @sortColumn
                sort_direction: @sortDirection

    removeRecord: (_id, name) ->
        console.log("removeRecord", @collection(), _id)
        @collection().remove _id, (error) ->
            if error
                console.log("Error deleting #{name}", error)
                CoffeeAlerts.error("Error deleting #{name}: #{error.reason}")
            else
                CoffeeAlerts.success("Deleted #{name}")


    # Mod THIS !!!
    doForm: (columns, options) =>
        if @formType == 'edit' and @recordID
            record = @model.findOne(@recordID)
        rtn = ''
        for key, column of columns
            col = jQuery.extend(true, {}, column)
            if col[@formType] or col["staticOn_#{@formType}"]
                col.displayType = col.type
                col.checkbox = false
                col.checked = ''
                if col.type is 'boolean'
                    col.displayType = 'checkbox'
                    col.checkbox = true
                    if record?[key]?
                        if record[key]
                            col.checked = 'checked'
                    else if col.default
                        col.checked = 'checked'
                else if record?[key]?
                    col.value = record[key]
                else if col.default?
                    col.value = col.default
                
                if col["staticOn_#{@formType}"]
                    col.static = true
                    if col.displayFunc?
                        col.value = col.displayFunc(col.value, columns)

                rtn += options.fn
                    'header': (col.header || key).capitalize()
                    'key': key
                    'col': col

        rtn

    editRecord: (_id) ->
        console.log("editRecord", _id)
        CoffeeModal.form "ironTableForm",  =>
 

    setupEvents: ->

        Template[@rowTemplate].events

            "click .iron-table-delete-record": (e, tmpl) =>
                console.log("delete record", e, tmpl, @)
                data = tmpl.data
                CoffeeModal.confirm "Are you sure you want to delete #{data.recordDisplayName}?", (yesNo) =>
                    if yesNo
                        console.log('delete', @)
                        @removeRecord(data._id, data.recordDisplayName)
                , "Delete"
                
            "click .iron-table-edit-record": (e, tmpl) =>
                console.log("edit record", e, tmpl, @)
                data = tmpl.data
                @editRecord(data._id)



