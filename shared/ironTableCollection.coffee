
class @IronTableCollection extends Meteor.Collection
    classID: 'IronTableCollection'
    
    recordName: 'record'
    colToUseForName : '_id'

    constructor: (name, options = null) ->
        super

        if Meteor.isServer
            # Meteor Method to get all the records in collection
            meths = {}
            meths["ironTable_" + @_name + "_recordCount"] = (select = {}) =>
                console.log("ironTable_" + @_name + "_recordCount called")
                @find?(select)?.count?()

            #meths["ironTable_" + @_name + "_remove"] = (select = {}) =>
            #    console.log("Remove Records", @_name, @isSimulation)
            #    @remove(select)
            
            Meteor.methods meths

    insertOk: ->
        false

    deleteAllOk: ->
        false

    deleteOk: (record) -> 
        false

    editOk: (record) -> 
        false



