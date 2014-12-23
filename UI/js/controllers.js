'use strict';
/* jshint  strict: true*/
/* global $, _, moment, errorHandler, angular */

var dashboardApp = angular.module('dashboardApp', ['dashFilters']);

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
});

dashboardApp.factory('Courses', function ($http) {
  return {
    getCourses: function (url) {

      return $http.get(url, {cache: true}).then(
        function success(result) {
          if(result.data.Meta.httpStatus !==200){
            result.errors = errorHandler(url, result);
            result.errors.failure = true;
            return result.errors;
          }
          else {
            if (!result.data.Result.length) {
              result.data.Result.message = 'You seem to have no courses this term.';
            }
            if (_.where(result.data.Result, {
                Source: 'CTools'
              }).length > 0) {
              result.data.Result.ctools = true;
            }
            if (_.where(result.data.Result, {
                Source: 'Canvas'
              }).length > 0) {
              result.data.Result.canvas = true;
            }
            $.each(result.data.Result, function (i, l) {
              l.Instructor = _.filter(l.Instructor, function (instructor) {
                return instructor.Role !== 'Dummy';
              });
            });
            return result.data.Result;
          }  
        },
        function error(result) {
          result.errors = errorHandler(url, result);
          result.errors.failure = true;
          return result.errors;
        }
      );
    }
  };
});

dashboardApp.controller('coursesController', ['Courses', '$rootScope', '$scope', function (Courses, $rootScope, $scope) {
  $scope.courses = [];
  $scope.loading = true;

  var url = 'courses/' + $rootScope.user + '.json';

  Courses.getCourses(url).then(function (data) {
    if (data.failure) {
      $scope.courses.errors = data;
      $scope.loading = false;
    } else {
      $scope.courses = data;
      $scope.loading = false;
    }
    $('.colHeader small').append($('<span id="#done" class="sr-only">' + $scope.courses.length + ' courses </span>'));

  });
}]);


dashboardApp.controller('termsController', ['Courses', '$rootScope', '$scope', '$http', function (Courses, $rootScope, $scope, $http) {
  $scope.selectedTerm = null;
  $scope.terms = [];
 
  var termsUrl = 'terms';

  $http.get(termsUrl).success(function (data) {
    $scope.terms = data;
    $scope.$parent.term = data[0].term;
    $scope.$parent.year = data[0].year;
  });

  $scope.getTerm = function (termId, term, year) {
    $scope.$parent.loading = true;
    $scope.$parent.courses = [];
    $scope.$parent.term = term;
    $scope.$parent.year = year;
    var url = 'courses/' + $rootScope.user + '.json'+ '?TERMID='+termId;

    Courses.getCourses(url).then(function (data) {
      if (data.failure) {
        $scope.$parent.courses.errors = data;
        $scope.$parent.loading = false;
      } else {
          $scope.$parent.courses = data;
          $scope.$parent.loading = false;
      }
    });

  };

}]);


dashboardApp.controller('scheduleController', ['$scope', '$http', function ($scope, $http) {
  var url = 'data/sched.json';
  $http.get(url).success(function (data) {
    $scope.schedule = data;
  });
}]);

dashboardApp.controller('todoController', ['$scope', '$http', function ($scope, $http) {
  var url = 'data/todo.json';

  $http.get(url).success(function (data) {
    $scope.todos = data;
    $scope.isOverdue = function (item) {
      //return item.due;
      var when = moment.unix(item.due);
      var now = moment();
      if (when < now) {
        return 'overdue';
      }
    };
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
  //var url = 'https://events.umich.edu/week/json'
  $http.get(url).success(function (data) {
    $scope.unievents = data;
  });
}]);
