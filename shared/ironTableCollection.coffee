
class @IronTableCollection extends Meteor.Collection
    classID: 'IronTableCollection'
    
    constructor: (name, options = null) ->
        if not @recordName?
            @recordName = 'record'
        super
        @setPermissions()
        @_title =  @getName().capitalize()
        @_subscription = @_name
        @_setAttributes()
        @_setColumns()

        if Meteor.isServer
            ironTableSetup(@)

    log: (args...) ->
        if @classID then args.unshift("(#{@classID})")
        console?.log?(args...)
        @

    debug: (args...) =>
        if @DEBUG? and @DEBUG
            @log(args...)

    getName: ->
        @_name

    getTitle: ->
        @_title

    setTitle: (@_title) ->

    setSubscription: (@_subscription) ->

    getSubscription: ->
        @_subscription

    setRecordName: (@recordName) ->

    getRecordName: (cap = false) ->
        if cap
            @recordName.capitalize()
        else
            @recordName

    _onInsert: (doc) ->
        @log('_onInsert',doc)
        for key, val of @getColumns?()
            if val.onInsert?
                if typeof val.onInsert is 'function'
                    doc[key] = val.onInsert()
                else
                    doc[key] = val.onInsert
            else if val.default? and not doc[key]?
                if typeof val.default is 'function'
                    doc[key] = val.default()
                else
                    doc[key] = val.default
        @log('after _onInsert',doc)
        doc

    _onUpdate: (docs) ->
        for doc in docs
            for key, val of @getColumns?()
                if val.onUpdate?
                    if typeof val.onUpdate is 'function'
                        console.log('_onUpdate', doc, key, doc[key], val.onUpdate(), val.onUpdate)
                        doc[key] = val.onUpdate(val)
                    else
                        doc[key] = val.onUpdate
        console.log(doc)
        docs

    beforeUpdate: (doc) ->
        @_onUpdate([doc])[0]

    setPermissions: ->
        # Set up defaults for insert and update
        # Does not deny anything just sets defaults !!!

        @deny
            insert: (userId, doc) =>
                doc = @_onInsert(doc)
                false

            # Not working.... I think they pass in a copy
            #update: (userId, docs) =>
            #   docs = @_onUpdate(docs)
            #   false
            remove: (userId, docs) =>
                if @_beforeRemove?
                    not _.all docs, (doc) =>
                        @_beforeRemove(userId, doc)
                else
                    false    
                
    _updateFields: ->
        fields = []
        for key, val of @getColumns?()
            if val.edit or val.onUpdate?
                fields.push(key)
        fields

    _setColumns: ->
        @_columns = @constructor.Columns?() || {}

    getColumns: ->
        @_columns

    getColumn: (key) ->
        @_columns[key]

    getAttributes: ->
        @_attributes

    _setAttributes: ->
        @_attributes = _.extend(IronTableCollection.Attributes(), @constructor.Attributes?() || {})
        @_attributes.name = @getName()
        @_attributes.title = @getTitle()
        @_attributes

    defaultSort: ->
        null

    @combineObjects: (localObj, parentObj) ->
        for key, val of parentObj
            if not localObj[key]?
                localObj[key] = val
        localObj

    @Attributes: ->
        editOK: false
        insertOK: false
        deleteOK: false
        deleteAllOK: false

