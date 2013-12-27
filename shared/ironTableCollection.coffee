
class @IronTableCollection extends Meteor.Collection
    classID: 'IronTableCollection'
    
    recordName: 'record'
    colToUseForName : '_id'

    constructor: (name, options = null) ->
        super

        if Meteor.isServer
            # Meteor Method to get all the records in collection
            meths = {}
            meths["ironTable_" + @_name + "_recordCount"] = (select = {})=>
                console.log("recordCount", @_name, @find?(select)?.count?())
                @find?()?.count?()
            
            Meteor.methods meths

    insertOk: ->
        false

    deleteAllOk: ->
        false

    deleteOk: (record) -> 
        false

    editOk: (record) -> 
        false



