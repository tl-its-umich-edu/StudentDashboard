'use strict';
/* jshint  strict: true*/
/* global $, _, moment, errorHandler, angular */

var dashboardApp = angular.module('dashboardApp', ['dashFilters']);

/**
 * Initialize Angular app with the user id and the strings file
 */

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
  $rootScope.lang = JSON.parse($('#lang').text());
});

/**
 * Singleton that does the requests for the courses
 * Inner function uses the URL passed to it
 */

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
            // the ESB might return a single object if only one course - turn it into an array
            if(result.data.Result.length === undefined) {
              result.data.Result =  [].concat(result.data.Result);
            }
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
              $.each(l.Instructor, function (i, l) {
                switch (l.Role) {
                case 'Primary Instructor':
                  l.RoleCode = 1;
                  break;
                case 'Secondary Instructor':
                  l.RoleCode = 2;
                  break;
                case 'Graduate Student Instructor':
                  l.RoleCode = 3;
                  break;
                case 'Faculty Grader':
                  l.RoleCode = 4;
                  break;
                default:
                  l.RoleCode = 4;
                }
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

/**
 * Singleton that does the requests for the terms
 * Inner function uses the URL passed to it
 */

dashboardApp.factory('Terms', function ($http) {
  return {
    getTerms: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
         if(result.data.Meta.httpStatus !==200){
            result.errors = errorHandler(url, result);
            result.errors.failure = true;
            return result.errors;
          }
          else {
            return result.data;
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

/**
 * Terms controller - Angular dependencies are injected.
 * It adds the terms to the scope and binds them to the DOM
 * 
 */
dashboardApp.controller('termsController', ['Courses', 'Terms', '$rootScope', '$scope',  function (Courses, Terms, $rootScope, $scope) {
  $scope.selectedTerm = null;
  $scope.terms = [];
 
  var termsUrl = 'terms';

  //use the Terms factory as a promise. Add returned data to the scope

  Terms.getTerms(termsUrl).then(function (data) {
    // the ESB might return a sinble object rather than an array, turn it into an array
    if (data.Result.length === undefined ){
      data.Result = [].concat(data.Result);
    }
    $scope.terms = data.Result;
    $scope.$parent.term = data.Result[0].TermDescr;
    $scope.$parent.termId = data.Result[0].TermCode;

    $scope.courses = [];
    $scope.loading = true;
    var url = 'courses/' + $rootScope.user + '.json?TERMID=' + $scope.$parent.termId;

  //use the Courses factory as a promise. Add returned data to the scope.

    Courses.getCourses(url).then(function (data) {
      if (data.failure) {
        $scope.courses.errors = data;
        $scope.loading = false;
      } else {
        $scope.courses = data;
        $scope.loading = false;
      }
      $('.colHeader small').append($('<span id="done" class="sr-only">' + $scope.courses.length + ' courses </span>'));
    });
  });  

  //Handler to change the term and retrieve the term's courses, using Course factory as a promise

  $scope.getTerm = function (termId, termName) {
    $scope.loading = true;
    $scope.courses = [];
    $scope.$parent.term = termName;
    
    var url = 'courses/' + $rootScope.user + '.json'+ '?TERMID='+termId;

    Courses.getCourses(url).then(function (data) {
      if (data.failure) {
        $scope.courses.errors = data;
        $scope.loading = false;
      } else {
          $scope.courses = data;
          $scope.loading = false;
      }
    });

  };

}]);

/**
 * Following controllers are for the portions of the dashboard yet to be 
 * developed.
 */

/*
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
*/