
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

    headers: =>
        rtn = []
        for colName in @cols
            rtn.push 
                colName: colName
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
            for col in @cols
                if @colFunc?[col]?  # Check that it is a function
                    value = @colFunc?[col](record[col])
                else
                    value = record[col]
                colData.push
                    value: value
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

    removeRecord: (_id) ->
        console.log("removeRecord", @collection(), _id)
        @collection().remove(_id)

    setupEvents: ->
        
        Template[@headerTemplate].events

            "click .table-col-head": (e, tmpl) =>
                e.preventDefault()
                console.log('click')
                if @_sessEquals("sortOn", tmpl.data.colName)
                    console.log('invert')
                    @_sess("sortDirection", - (@_sess("sortDirection")))
                else
                    @_sess("sortDirection", 1)
                    @_sess("sortOn", tmpl.data.colName)  


        Template[@rowTemplate].events

            "click .iron-table-delete-record": (e, tmpl) =>
                console.log("delete record", e, tmpl, @)
                data = tmpl.data
                CoffeeModal.confirm "Are you sure you want to delete #{data.recordDisplayName}?", =>
                    console.log('delete', @)
                    @removeRecord(data._id)
                , "Delete"
                
            "click .iron-table-edit-record": (e, tmpl) =>
                console.log("edit record", e, tmpl)



