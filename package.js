Package.describe({
  summary: 'Paging Table for IronRouter and Meteor'
});

Package.on_use(function (api, where) {
  
  // Client
  api.use(
    [
    'deps',
    'minimongo', 
    'mongo-livedata',
    'templating',
    'spark',
    'handlebars',
    'jquery',
    'session',
    'spin',
    'less'
    ]
    , 'client');

  api.add_files(
    [
    'client/ironTable.html',
    'client/ironTable.less',
    'client/ironTable.coffee'
    ]
    , 'client');

  api.add_files(
    [
    'shared/ironTableController.coffee',
    'shared/ironTableSetup.coffee'
    ]
    , ['client','server']);

  // Server
  /*
  api.add_files([
    'server/ironTableMethods.coffee'
  ], 'server');
  */

  // Server and Client
  api.use([
    'underscore',
    'coffeescript',
    'iron-router'
    ], ['client', 'server']);
  
  if (api.export) {
    //api.export('IronTableController', ['client','server']);
    api.export('ironTableSetup', ['client','server']);  
  }
    
});


Package.on_test(function (api) {
  
});
