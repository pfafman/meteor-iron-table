
Package.describe({
  //name: 'pfafman:meteor-iron-table-materialize',
  summary: "Paging Table for IronRouter and Meteor with Materialize styling",
  version: "0.3.0",
  git: "https://github.com/pfafman/meteor-iron-table-materialize.git",
});

Package.on_use(function (api, where) {
  api.versionsFrom("METEOR@1.0.4");

  // Client
  api.use(
    [
    'templating',
    'jquery',
    'session',
    'less',
    'pfafman:materialize-modal',
    'reactive-var',
    'pfafman:filesaver',
    ]
    , 'client');

  api.imply('pfafman:materialize-modal');

  api.add_files(
    [
    'client/ironTable.html',
    'client/ironTable.less',
    'client/ironTable.coffee',
    'client/ironTableForm.html',
    'client/ironTableForm.coffee',
    'client/helpers/ironTableCheckbox.html',
    'client/helpers/ironTableCheckbox.coffee',
    'client/helpers/ironTableSelect.html',
    'client/helpers/ironTableSelect.coffee',
    ]
    , 'client');

  api.add_files(
    [
    'shared/ironTableController.coffee',
    'shared/ironTableCollection.coffee',
    'shared/t9n.coffee'
    ]
    , ['client','server']);

  // Server and Client
  api.use([
    'underscore',
    'coffeescript',
    'mongo',
    'iron:router',
    'softwarerero:accounts-t9n',
    ], ['client', 'server']);


  if (api.export) {
    //api.export('IronTableController', ['client','server']);
    //api.export('ironTableSetup', ['client','server']);
  }

});


Package.on_test(function (api) {

});
