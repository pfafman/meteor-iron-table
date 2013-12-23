
class @IronTableController extends RouteController

    constructor: ->
        console.log("IronTableController constuct", @collection()._name)
        super
        
        Meteor.defer =>
            @setupEvents()

    increment       : 20
    defaultSort     : '_id'
    colToUseForName : '_id'

    template        : 'ironTable'
    rowTemplate     : 'ironTableRow'
    headerTemplate  : 'ironTableHeader'
    
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
        if not @_sess("sortOn")
            @_sess("sortOn", @defaultSort)
        if not @_sess("sortDirection")
            @_sess("sortDirection", 1)

        Meteor.call 'ironTable_' +  @_collectionName() + '_recordCount', (error, number) =>
            if not error and not @_sessEquals("recordCount", number)
                @_sess("recordCount", number)
            else if error 
                console.log('ironTable_' +  @_collectionName() + '_recordCount error:', error)

    #after: ->
    #    @setEvents()

    unload: ->
        console.log("unload")
        #@_sessNull("sortOn")
        #@_sess("sortDirection", 1)

    
    _tableTitle: ->
        @tableTitle or @_collectionName() #.capitalize()

    _collectionName: ->
        @collectionName or @collection()._name

    _recordName: ->
        @recordName or @collection()._name

    _cols: ->
        theCol = @cols or @collection()?.getColumns?()
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
            rtn.push 
                colName: colName
                col: colObj
                sort: @_sessEquals("sortOn", colName)
                desc: @_sessEquals("sortDirection", -1)
        rtn

    limit: ->
        @increment

    skip: ->
        parseInt(@params.skip) or 0
    
    sort: ->
        sortOn = @_sess("sortOn") or @defaultSort
        direction = @_sess("sortDirection") or 1
        rtn = {}
        rtn["#{sortOn}"] = direction
        rtn

    waitOn: ->
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
                if colObj.func?  # Check that it is a function
                    value = olObj.func(record[col])
                else
                    value = record[col]
                colData.push
                    value: value
                    #aLink: "http://nowhere.com"
            recordData.push
                colData: colData
                _id: record._id
                recordDisplayName: @_recordName() + ' ' + record[@colToUseForName]
                editOk: @editOk(record)
                deleteOk: @deleteOk(record)

        rtn =
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

    previousPath: ->
        Router.current().route.path
            skip: @skip() - @increment

    removeRecord: (_id, name) ->
        console.log("removeRecord", @collection(), _id)
        @collection().remove _id, (err) ->
            if err
                CoffeeAlerts.error("Error deleting record #{name}")
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
        CoffeeModal.form "", =>
 

    setupEvents: ->
        Template[@headerTemplate].events

            "click .table-col-head": (e, tmpl) =>
                e.preventDefault()
                console.log('click', tmpl.data.colName)
                if @_sessEquals("sortOn", tmpl.data.colName)
                    @_sess("sortDirection", - (@_sess("sortDirection")))
                else
                    @_sess("sortDirection", 1)
                    @_sess("sortOn", tmpl.data.colName)  


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



