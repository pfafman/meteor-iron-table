

ironTableSetup = (collection) ->
    if Meteor.isServer
        @meths = {}
        
        @meths["ironTable_" + collection._name + "_recordCount"] = ->
            console.log("recordCount", collection._name)
            collection.find().count()
        
        Meteor.methods @meths