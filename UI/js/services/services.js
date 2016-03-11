'use strict';
/* global dashboardApp */

dashboardApp.service('canvasShare',function($rootScope){
  var service = {};
  service.data = false;
  service.sendData = function(data){
      this.data = data;
      $rootScope.$broadcast('canvas_shared');
  };
  service.getData = function(){
    return this.data;
  };
  return service;
});
