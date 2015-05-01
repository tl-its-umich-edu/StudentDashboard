'use strict';
/* jshint  strict: true*/
/* global $, _, moment, errorHandler, angular */

var dashboardApp = angular.module('dashboardApp', ['ngAnimate','dashFilters','xeditable']);

/**
 * Initialize Angular app with the user id and the strings file
 */

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
  $rootScope.lang = JSON.parse($('#lang').text());
});

dashboardApp.run(function(editableOptions, editableThemes) {
  editableThemes.bs3.inputClass = 'input-xs';
  editableThemes.bs3.buttonsClass = 'btn-xs';
  editableOptions.theme = 'bs3';
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
    if (data.failure) {
      $scope.$parent.term  = $rootScope.lang.termFailure;
    }
    else {
      // the ESB might return a single object rather than an array, turn it into an array
      if (data.Result.length === undefined ){
        data.Result = [].concat(data.Result);
      }
      if (data.Result.length !==0)  {

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
      } else {
        $scope.$parent.term  = 'You do not seem to have courses in any terms we know of.';
      }
    }    
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

dashboardApp.factory('ToDosCanvas', function ($http) {
  return {
    getToDos: function (url) {
      return $http.get(url, {cache: true}).then(
        function success(result) {
          return canvasToDoCleaner(result);
        },
        function error(result) {
          console.log('errors');
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
        function error(result) {
          console.log('errors');
        }
      );
    }
  };
});


dashboardApp.controller('newTodoController', ['ToDosCanvas','ToDosCTools', '$scope', '$http', function (ToDosCanvas, ToDosCTools, $scope, $http) {
  var canvasData = [];
  var ctoolsData = [];
  var GTasksData = []; 
  var combinedData = [];

  ToDosCanvas.getToDos('data/todo/canvas.json').then(function (data) {
    data = eval(data);
    canvasData = data;
    ToDosCTools.getToDos('data/todo/ctools.json').then(function (data) {
      ctoolsData = data;
      if(localStorage.getItem('toDoStore')){
        var toDoStore = GTasksToDoCleaner(eval(localStorage.getItem('toDoStore')));
      }  
      
      combinedData = combinedData.concat(canvasData,ctoolsData, toDoStore);
      
      $scope.todos = combinedData;
          
      $scope.todo_time_options = [
        {name:'Earlier', value:'earlier'},
        {name:'Soon', value:'soon'},
        {name:'Later', value:'later'},
      ];
      $scope.showWhen = 'soon';

      $scope.isOverdue = function (item) {
        var when = moment.unix(item.due_date_sort);
        var now = moment();
        if (when < now) {
          return 'overdue';
        }
      };

      $scope.enableEditor = function() {
         $scope.editorEnabled = true;
      }
      $scope.disableEditor = function() {
        $scope.editorEnabled = false;
      };
      $scope.newToDo = function () {
        var newObj = {};
        newObj.title = $('#toDoTitle').val();
        newObj.message = $('#toDoMessage').val();
        newObj.origin='gt';
        //newObj.when='soon';
        newObj.due_date = moment($('#newToDoDate').val()).format("dddd, MMMM Do YYYY, h:mm a");
        newObj.due_date_short = moment($('#newToDoDate').val()).format("MM/DD");
        newObj.due_date_sort = moment($('#newToDoDate').val()).unix().toString();

        $scope.todos.push(newObj);

        //strip Angular state info before storing
        localStorage.setItem('toDoStore', JSON.stringify(_.where($scope.todos, {origin: 'gt'}), function (key, val) {
           if (key == '$$hashKey') {
               return undefined;
           }
           return val;
        }));

      };
      $scope.removeToDos = function () {
        alert('removing something!');
        //$scope.todos.push(newObj)
      };

    });
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




dashboardApp.controller('scheduleController', ['getMapCoords', 'pageDay', '$scope', '$http', function (getMapCoords, pageDay, $scope, $http) {
  var url = 'data/schedule/schedule.json';
  $http.get(url).success(function (data) {
    var wdayint = moment().weekday();
  
    $scope.weekdayAbbr = pageDay.getDay(wdayint)[0];
    $scope.dateWeek = moment().format('dddd');

    $.each(data.getMyClsScheduleResponse.RegisteredClass, function (i, l) {
      var AggrMeeting ='';
      var AggrLocation =[];
      var parseableTime = '';
      if(l.Meeting.length){
        $.each(l.Meeting, function (i, l) {
            AggrMeeting  = AggrMeeting  + l.Days;
            AggrLocation.push(l.Location);
            //console.log(AggrLocation)
            if (l.Times.split('-')[0].indexOf('PM') !== -1) {
              var tempTime = parseInt(l.Times.split('-')[0].replace('PM','').split(':')[0]) + 12;
              parseableTime = tempTime + l.Times.split('-')[0].replace('PM','').split(':')[1];
            }
            else  {
              parseableTime = l.Meeting.Times.split('-')[0].replace('AM','').replace(':','');
            }
        });    
      } 
      else {
        AggrMeeting = l.Meeting.Days;
        AggrLocation.push(l.Meeting.Location);

        if (l.Meeting.Times.split('-')[0].indexOf('PM') !== -1) {
          var tempTime = parseInt(l.Meeting.Times.split('-')[0].replace('PM','').split(':')[0]) + 12;
          parseableTime = tempTime  + l.Meeting.Times.split('-')[0].replace('PM','').split(':')[1];
        }
        else  {
          parseableTime = l.Meeting.Times.split('-')[0].replace('AM','').replace(':','');
        }
      }
      //console.log(AggrLocation)
      l.Meeting.AggrLocation = AggrLocation;
      if(parseableTime ===''){
        parseableTime = '2500';
      }

      l.parseableTime = parseInt(parseableTime);

      if (AggrMeeting !=='') {
        l.AggrMeeting = AggrMeeting;
      }
      else {
        //might consider explicitly filtering this out
        l.AggrMeeting = 'NA';
      }
    });
    
    $scope.schedule = data.getMyClsScheduleResponse.RegisteredClass;

    $scope.openMap = function ( building, mobile) {
      getMapCoords.getCoords(building).then(function (data) {
        if (data.failure) {
           //report error 
        } else {
          // open new Google maps window with directions from current location
          if (mobile) {
            window.open('https://www.google.com/maps/dir/Current+Location/' + data.latitude + ',' + data.longitude);
          }
          else {
            window.open('http://maps.google.com/maps?q=' + data.latitude + ',' + data.longitude);
          }

        }
      });
    };

    $scope.pageDay = function (dir) {
      var wdayintnew;
      if(dir === 'next') {
        if (wdayint === 7) {
          wdayintnew = 1;
        }
        else {
          wdayintnew = wdayint + 1;
        }
      }
      else {
        if (wdayint === 1) {
          wdayintnew = 7;
        }
        else {
          wdayintnew = wdayint - 1;
        }
      }

      wdayint = wdayintnew;
      
      $scope.weekdayAbbr = pageDay.getDay(wdayint)[0];
      $scope.dateWeek = pageDay.getDay(wdayint)[1];
    };
  });
}]);

dashboardApp.directive( 'editInPlace', function() {
  return {
    restrict: 'E',
    scope: { value: '=' },
    template: '<span ng-click="edit()" ng-bind="value"></span><input ng-model="value">',
    link: function ( $scope, element, attrs ) {
      // Let's get a reference to the input element, as we'll want to reference it.
      var inputElement = angular.element( element.children()[1] );
      
      // This directive should have a set class so we can style it.
      element.addClass( 'edit-in-place' );
      
      // Initially, we're not editing.
      $scope.editing = false;
      
      // ng-click handler to activate edit-in-place
      $scope.edit = function () {
        $scope.editing = true;
        
        // We control display through a class on the directive itself. See the CSS.
        element.addClass( 'active' );
        
        // And we must focus the element. 
        // `angular.element()` provides a chainable array, like jQuery so to access a native DOM function, 
        // we have to reference the first element in the array.
        inputElement[0].focus();
      };
      
      // When we leave the input, we're done editing.
      inputElement.prop( 'onblur', function() {
        $scope.editing = false;
        element.removeClass( 'active' );
      });
    }
  };
});