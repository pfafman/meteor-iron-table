

ironTableSetup = (collection) ->
    if Meteor.isServer
        console.log("ironTableSetup", "ironTable_" + collection._name + "_recordCount")
        @meths = {}
        
        @meths["ironTable_" + collection._name + "_recordCount"] = ->
            
            console.log("Find Max")
            collection.find().count()
        
        Meteor.methods @meths
        
