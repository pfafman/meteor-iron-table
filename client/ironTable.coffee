
Template.ironTableHeader.events
    "click .table-col-head": (e, tmpl) ->
        e.preventDefault()
        if Session.equals("_ironTable_sortOn", tmpl.data.colName)
            Session.set("_ironTable_sortDirection", -(Session.get("_ironTable_sortDirection")))
        else
            Session.set("_ironTable_sortDirection", 1)
            Session.set("_ironTable_sortOn", tmpl.data.colName)           

Template.ironTableRow.events
    "click .iron-table-delete-record": (e, tmpl) ->
        console.log("delete record", e, tmpl)

    "click .iron-table-edit-record": (e, tmpl) ->
        console.log("edit record", e, tmpl)