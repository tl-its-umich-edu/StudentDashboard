'use strict';
/* jshint  strict: true*/
/* global $, errorHandler, _, dashboardApp */

/**
 * Singleton that reads index of external messages and picks one
 */


dashboardApp.factory('DashMessage', function ($http) {
  return {
    getMessageIndex: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
          return result.data;
        },
        function error(result) {
          return result.errors;
        }
      );
    },
    getMessage: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
          return result.data;
        },
        function error(result) {
          return result.errors;
        }
      );
    }
  };
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
            $.each(result.data.Result, function (i, l) {
              $.each(l.Meeting, function (i, m) {
                switch (m.Days.substring(0,2)) {
                case 'Mo':
                  m.DayCode = 1;
                  break;
                case 'Tu':
                  m.DayCode = 2;
                  break;
                case 'We':
                  m.DayCode = 3;
                  break;
                case 'Th':
                  m.DayCode = 4;
                  break;
                case 'Fr':
                  m.DayCode = 5;
                  break;
                case 'Sa':
                  m.DayCode = 6;
                  break;
                case 'Su':
                  m.DayCode = 7;
                  break;
                default:
                  m.DayCode = 7;
                }
              });
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
 *  Factory to return  the Canvas/CTools todo data as promise
 */

dashboardApp.factory('Schedule', function ($http) {
  return {
    getSchedule: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
          return prepareSchedule(result);
        },
        function error() {
          //console.log('errors');
        }
      );
    }
  };
});