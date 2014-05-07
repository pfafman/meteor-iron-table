
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
                    publishCount @, countName, collection.find(select,{_id:1}), 
                        noReady: true
                      
                    collection.find select, 
                        sort: sort
                        limit: limit
                        skip: skip
            

    insertOk: ->
        false

    deleteAllOk: ->
        false

    deleteOk: (record) -> 
        false

    editOk: (record) -> 
        false



