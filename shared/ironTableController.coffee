
class @IronTableController extends RouteController

    before: ->
        if not Session.get("_ironTable_sortOn")
            Session.set("_ironTable_sortOn", @_defaultSort())
        if not Session.get("_ironTable_sortDirection")
            Session.set("_ironTable_sortDirection", 1)

        Meteor.call 'ironTable_' +  @_collectionName() + '_recordCount', (error, number) =>
            if not error and not Session.equals("_ironTable_recordCount", number)
                Session.set("_ironTable_recordCount", number)
            else if error 
                console.log('ironTable_' +  @_collectionName() + '_recordCount error:', error)

    unload: ->
        console.log('unload')
        Session.set("_ironTable_sortOn", null)
        Session.set("_ironTable_sortDirection", 1)


    _increment: ->
        @increment or 20

    _defaultSort: ->
        @defaultSort or '_id'

    _tableTitle: ->
        @tableTitle or @_collectionName() #.capitalize()

    template: 'ironTable'

    _collectionName: ->
        @collectionName or @collection()._name

    headers: =>
        rtn = []
        for colName in @cols
            rtn.push 
                colName: colName
                sort: Session.equals("_ironTable_sortOn", colName)
                desc: Session.equals("_ironTable_sortDirection", -1)
        rtn

    limit: ->
        @_increment()

    skip: ->
        parseInt(@params.skip) or 0
    
    sort: ->
        sortOn = Session.get("_ironTable_sortOn") or @_defaultSort()
        direction = Session.get("_ironTable_sortDirection") or 1
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

        rtn =
            tableTitle: @_tableTitle()
            recordDisplayStart: @skip() + 1
            recordDisplayStop: @skip() + @_increment()
            records: recordData
            headers: @headers
            nextPath: @nextPath()
            nextPathClass: if (@skip() + @_increment() >= Session.get("_ironTable_recordCount")) then "disabled" else ""
            previousPath: @previousPath()
            previousPathClass: if (@skip() <= 0) then "disabled" else ""
            increment: @_increment()
            recordCount: Session.get("_ironTable_recordCount")

    nextPath: ->
        Router.current().route.path
            skip: @skip() + @_increment()

    previousPath: ->
        Router.current().route.path
            skip: @skip() - @_increment()




