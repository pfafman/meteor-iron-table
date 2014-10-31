Package.describe({
  summary: 'Paging Table for IronRouter and Meteor',
  version: "0.6.2",
  git: "https://github.com/pfafman/meteor-iron-table.git"
});

Package.on_use(function (api, where) {
  api.versionsFrom("METEOR@1.0");

  // Client
  api.use(
    [
    'deps',
    'minimongo',
    'mongo',
    'mongo-livedata',
    'templating',
    'handlebars',
    'jquery',
    'session',
    'sacha:spin',
    'less',
    'pfafman:coffee-alerts',
    'pfafman:coffee-modal',
    'reactive-var',
    'mrt:filesaver'
    ]
    , 'client');

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
    'shared/ironTableCollection.coffee'
    ]
    , ['client','server']);

  // Server and Client
  api.use([
    'underscore',
    'coffeescript',
    'iron:router'
    ], ['client', 'server']);

  if (api.export) {
    //api.export('IronTableController', ['client','server']);
    //api.export('ironTableSetup', ['client','server']);
  }

});


Package.on_test(function (api) {

});
