
class @IronTableCollection extends Meteor.Collection
    classID: 'IronTableCollection'
    
    recordName: 'record'
    colToUseForName : '_id'
    selfPublish: true

    constructor: (name, options = null) ->
        super

        if Meteor.isServer
            if @selfPublish
                collection = @
                countName = @_name + 'Count'
                Meteor.publish @_name, (select, sort, limit, skip) ->
                    #console.log("Iron Router Publish", countName)
                    #publishCount @, countName, collection.find(select,{_id:1}), 
                    #    noReady: true
                      
                    collection.find select, 
                        sort: sort
                        limit: limit
                        skip: skip

            meths = {}
            meths["ironTable_" + @_name + "_recordCount"] = (select = {}) =>
                @find?(select)?.count?()
            
            #if true #@doDownloadLink
            meths["ironTable_" + @_name + "_getCSV"] = (select = {}, fields = {}) =>
                csv = []
                fieldKeys = _.keys(fields)
                csv.push fieldKeys.join(',')
                cursor = @find? select,
                    fields: fields
                if cursor?.forEach?
                    cursor.forEach (rec) ->
                        row = []
                        for fieldKey in fieldKeys
                            row.push rec[fieldKey]
                        csv.push row.join(',')
                csv.join("\n")
                    

            Meteor.methods meths

    insertOk: ->
        false

    deleteAllOk: ->
        false

    deleteOk: (record) -> 
        false

    editOk: (record) -> 
        false



