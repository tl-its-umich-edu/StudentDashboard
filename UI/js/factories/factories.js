'use strict';
/* jshint  strict: true*/
/* global $, errorHandler, _, dashboardApp, canvasToDoCleaner, ctoolsToDoCleaner */

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


dashboardApp.factory('getMapCoords', function ($http) {
  return {
    getCoords: function (building) {
      var url = 'data/buildings/' + _.last(building.split(' ')).toLowerCase() + '.json';
      return $http.get(url, {cache: true}).then(
        function success(result) {
          var coords = {};
          coords.latitude = result.data.Buildings.Building.Latitude;
          coords.longitude = result.data.Buildings.Building.Longitude;
          return coords;
        },
        function error() {
          //do something in case of error
          //result.errors.failure = true;
          //return result.errors;
        }
      );
    }
  };
});


dashboardApp.factory('pageDay', function () {
  return {
      getDay: function (wdayintnew) {
        //wdayintnew=4; // for testing
        var weekday=new Array(7);
        weekday[1]=['Mo', 'Monday'];
        weekday[2]=['Tu', 'Tuesday'];
        weekday[3]=['We', 'Wednesday'];
        weekday[4]=['Th', 'Thursday'];
        weekday[5]=['Fr', 'Friday'];
        weekday[6]=['Sa', 'Saturday'];
        weekday[7]=['Su', 'Sunday'];
        return  weekday[wdayintnew];
      }
  };
});


dashboardApp.factory('ToDosCanvas', function ($http) {
  return {
    getToDos: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
          return canvasToDoCleaner(result);
        },
        function error() {
          //console.log('errors');
        }
      );
    }
  };
});

dashboardApp.factory('ToDosCTools', function ($http) {
  return {
    getToDos: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
            return ctoolsToDoCleaner(result);
        },
        function error() {
          //console.log('errors');
        }
      );
    }
  };
});