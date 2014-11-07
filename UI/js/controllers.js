/*jslint browser: true*/
/*global $, moment, errorHandler*/


var dashboardApp = angular.module('dashboardApp', ['dashFilters']);

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
});

dashboardApp.factory('Courses', function ($http) {
  return {
    getCourses: function (url) {
      return $http.get(url).then(function success(result) {
        if (!result.data.length) {
          result.data.message = "You seem to have no courses this term.";
        }
        if (_.where(result.data, {
            Source: "CTools"
          }).length > 0) {
          result.data.ctools = true;
        }
        if (_.where(result.data, {
            Source: "Canvas"
          }).length > 0) {
          result.data.canvas = true;
        }
        return result.data;
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

  var url = 'courses/' + $rootScope.user + '.json';
  // below for testing
  //var url = 'data/courses/anonymous.json';

  Courses.getCourses(url).then(function (data) {
    if (data.failure) {
      $scope.courses.errors = data;
    } else {
      $scope.courses = data;
    }

  });
}]);


dashboardApp.controller('termsController', ['Courses', '$rootScope', '$scope', '$http', function (Courses, $rootScope, $scope, $http) {
  $scope.selectedTerm = null;
  $scope.terms = [];
  //var termsUrl = 'data/terms.json';
    var termsUrl = 'terms';

  $http.get(termsUrl).success(function (data) {
    $scope.terms = data;
    $scope.$parent.term = data[0].term;
    $scope.$parent.year = data[0].year

  });

  $scope.getTerm = function (termId, term, year) {
    $scope.$parent.courses = [];
    $scope.$parent.term = term;
    $scope.$parent.year = year;
    var url = 'courses/' + $rootScope.user + '.json&term=' + "?TERMID="+termId;

    Courses.getCourses(url).then(function (data) {
      if (data.failure) {
        $scope.$parent.courses.errors = data;
      } else {
        $scope.$watch('courses', function () {
          $scope.$parent.courses = data;
        });
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