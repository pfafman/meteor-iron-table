
Template.ironTableHeader.events
    "click .table-col-head": (e, tmpl) =>
        e.preventDefault()
        if Session.equals("_ironTable_sortOn", tmpl.data.colName)
            Session.set("_ironTable_sortDirection", -(Session.get("_ironTable_sortDirection")))
        else
            Session.set("_ironTable_sortDirection", 1)
            Session.set("_ironTable_sortOn", tmpl.data.colName)           
