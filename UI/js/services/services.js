'use strict';
/* global dashboardApp */
dashboardApp.service('shareCanvas', [function () {
    var canvasArray = [];
    this.setCanvasArray = function(newArr) {
       canvasArray = newArr;
       return canvasArray;
    };
    this.getCanvasArray = function(){
        return canvasArray;
    };
}]);
