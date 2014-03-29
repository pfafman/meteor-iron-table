
getCurrentIronTableController = ->
    if Router.current?()?.classID is "IronTableController"
        Router.current()
    else
        console.log("Bad controller", Router.current?())
        null


#Template.ironTable.created = ->
#    console.log("ironTable created")


#Template.ironTable.rendered = ->
    #$('[rel="tooltip"]').tooltip()
    #$('[rel="popover"]').popover()


#Template.ironTable.destroyed = ->
    #console.log("ironTable destroyed")


Template.ironTable.events

    "click .iron-table-delete-record": (e, tmpl) ->
        e.preventDefault()
        #e.stopImmediatePropagation()
        
        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false
        
        CoffeeModal.confirm "Are you sure you want to delete #{@recordDisplayName}?", (yesNo) =>
            if yesNo
                currentController.removeRecord(@)
        , "Delete"
        
    "click .iron-table-edit-record": (e, tmpl) ->
        e.preventDefault()
        #e.stopImmediatePropagation()
    
        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false

        currentController.editRecord(@_id)



Template.ironTableFilter.events

    "change #filter-column": (e, tmpl) ->
        #e.preventDefault()
        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false

        currentController.setFilterColumn(e.target.value)


    "keypress, change #filter-value": (e, tmpl) ->
        #e.preventDefault()
        #console.log("filter-value", e.target.value, $("#filter-value").val())
        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false
        Meteor.defer ->
            currentController.setFilterValue(e.target.value)

    "submit form": (e) ->
        e.preventDefault()
        console.log("submit", $("#filter-value").val())


Template.ironTableRow.helpers
    extraControls: ->
        if currentController = getCurrentIronTableController()
            if currentController.extraControlsTemplate?
                Template[currentController.extraControlsTemplate] #(@)

    templateRow: ->
        Template[@template]


Template.ironTableRow.rendered = ->
    $('[rel="tooltip"]').tooltip()

Template.ironTableHeader.rendered = ->
    $('[rel="tooltip"]').tooltip()
    

