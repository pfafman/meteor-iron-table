
getCurrentIronTableController = ->
    if Router.current?()?.classID is "IronTableController"
        Router.current()
    else
        console.log("Bad controller", Router.current?())
        null


Template.ironTable.created = ->
    console.log("ironTable created")


Template.ironTable.rendered = ->
    console.log("ironTable rendered")
    $('[rel="tooltip"]').tooltip()
    $('[rel="popover"]').popover()


Template.ironTable.destroyed = ->
    console.log("ironTable destroyed")


Template.ironTable.events

    "click .iron-table-delete-record": (e, tmpl) ->
        e.preventDefault()
        #e.stopImmediatePropagation()
        console.log("delete record", e, tmpl, @, Router.current?(), Router.current?().classID)

        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false
        
        CoffeeModal.confirm "Are you sure you want to delete #{@recordDisplayName}?", (yesNo) =>
            if yesNo
                console.log('delete', @)
                currentController.removeRecord(@)
        , "Delete"
        
    "click .iron-table-edit-record": (e, tmpl) ->
        e.preventDefault()
        #e.stopImmediatePropagation()
        console.log("edit record", e, tmpl, @, Router.current?())

        if not currentController = getCurrentIronTableController()
            CoffeeAlerts.error("Internal Error: Could not get controller")
            return false

        currentController.editRecord(@_id)



