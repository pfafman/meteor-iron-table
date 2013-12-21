

ironTableSetup = (collection) ->
    if Meteor.isServer
        @meths = {}
        
        @meths["ironTable_" + collection._name + "_recordCount"] = ->
            collection.find().count()
        
        Meteor.methods @meths
        
