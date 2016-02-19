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
              if(l.Meeting) {
                $.each(l.Meeting, function (i, m) {
                  if(m.Days){
                    var dayCode = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].indexOf(m.Days.substring(0, 2)) + 1;
                    m.DayCode = (dayCode == 0) ? 7 : dayCode;
                  }
                });
              }
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
        function error(result) {
          return result
        }
      );
    }
  };
});