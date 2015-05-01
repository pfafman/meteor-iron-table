
DEBUG = false

class @IronTableCollection extends Mongo.Collection
  classID: 'IronTableCollection'
  
  recordName: 'record'
  colToUseForName : '_id'
  selfPublish: true
  publishCounts: false


  publicationName: ->
    'ironTable_publish_' + @_name

  countName: ->
    @_name + 'Count'

  name: ->
    @_name

  constructor: (name, options = null) ->
    super

    if Meteor.isServer
      if @selfPublish
        collection = @

        if @publishCounts
          countName = @countName()

        Meteor.publish @publicationName(), (select, sort, limit, skip) ->
          
          if countName
            publishCount @, countName, collection.find(select),
              noReady: true

          collection.find select,
            sort: sort
            limit: limit
            skip: skip


      meths = {}
      if not @publishCounts
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
              subElements = fieldKey.split('.')
              value = rec
              for subElement in subElements
                value = value?[subElement]
              row.push value
            csv.push row.join(',')
        csv.join("\n")
              
      Meteor.methods meths


  insertOk: (record)->
    # Check Record Here on insert
    false


  deleteAllOk: ->
    false


  deleteOk: (record) ->
    false


  editOk: (record) ->
    false



