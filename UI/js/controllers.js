var dashboardApp = angular.module('dashboardApp', ['dashFilters']);

var userId = $('#userId').text();

dashboardApp.controller('scheduleController', ['$scope', '$http', function ($scope, $http) {
  var url ='data/sched.json';
  $http.get(url).success(function (data) {
    $scope.schedule = data;
  });
}]);

dashboardApp.controller('coursesController', ['$scope', '$http', function ($scope, $http) {
  var url = 'courses/' + userId + '.json';
  $http.get(url).success(function (data) {
    $scope.courses = data;
  });
}]);

dashboardApp.controller('todoController', ['$scope', '$http', function ($scope, $http) {
  var url = 'data/todo.json';

  $http.get(url).success(function (data) {
    $scope.todos = data;
    $scope.isOverdue = function(item){
        //return item.due;
        var when = moment.unix(item.due);
        var now = moment();
        if(when <  now){
            return 'overdue';
        }
    }
  });
}]);

dashboardApp.controller('eventsController', ['$scope', '$http', function ($scope, $http) {
  var url = 'data/events.json';
  $http.get(url).success(function (data) {
    $scope.events = data;
  });
}]);

dashboardApp.controller('uniEventsController', ['$scope', '$http', function ($scope, $http) {
  var url = 'data/uniWeekEvents.json';
  //var url = 'data/uniEvents.json';
  var url = 'https://events.umich.edu/week/json'
  $http.get(url).success(function (data) {
    $scope.unievents = data;
  });
}]);
