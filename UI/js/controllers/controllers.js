'use strict';
/* jshint  evil: true, strict: true, unused:true, eqnull:true */
/* global $, _, moment, dashboardApp, GTasksToDoCleaner, localStorateUpdateTodos */

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
 * Schedule controller. Angular dependencies are injected - using canned data for now
 */

dashboardApp.controller('scheduleController', ['Schedule', 'getMapCoords', 'pageDay', '$scope', '$http', function (Schedule, getMapCoords, pageDay, $scope, $http) {
  var scheduleUrl = 'data/schedule/schedule.json';
  var wdayint = moment().weekday();

  $scope.weekdayAbbr = pageDay.getDay(wdayint)[0];
  $scope.dateWeek = moment().format('dddd');

  Schedule.getSchedule(scheduleUrl).then(function (data) {
    if (data.failure) {
      $scope.$parent.term  = $rootScope.lang.termFailure;
    }
    else {
      $scope.schedule = data;
    }    
  });  

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
}]);

/**
 * Todo controller, using fake data for now
 */

dashboardApp.controller('todoController', ['ToDosCanvas','ToDosCTools', '$scope', function (ToDosCanvas, ToDosCTools, $scope) {
  var canvasData = [];
  var ctoolsData = [];
  var combinedData = [];

  ToDosCanvas.getToDos('data/todo/canvas.json').then(function (data) {
    data = eval(data);
    canvasData = data;
    ToDosCTools.getToDos('data/todo/ctools.json').then(function (data) {
      ctoolsData = data;
      if(localStorage.getItem('toDoStore')){
        var toDoStore = GTasksToDoCleaner(eval(localStorage.getItem('toDoStore')));
        combinedData = combinedData.concat(canvasData,ctoolsData, toDoStore);
      }
      else {
        combinedData = combinedData.concat(canvasData,ctoolsData);
      }  
      
      
      
      $scope.todos = combinedData;
      
      /* to debug sorting issues
      $.each(combinedData, function() {
        console.log( this.due_date_sort +  ': ' + this.title)
      })
      */
     
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

      $scope.newToDo = function () {
        var newObj = {};
        newObj.title = $('#toDoTitle').val();
        newObj.message = $('#toDoMessage').val();
        newObj.origin='gt';
        newObj.due_date = moment($('#newToDoDate').val()).format('dddd, MMMM Do YYYY, h:mm a');
        newObj.due_date_short = moment($('#newToDoDate').val()).format('MM/DD');
        newObj.due_date_editable = moment($('#newToDoDate').val()).format('YYYY-MM-DD');
        newObj.due_time_editable = $('#newToDoTime').val();
        newObj.due_date_sort = moment($('#newToDoDate').val()).unix();

        var nowDay = moment().unix().toString();
        var nowDayAnd4 = moment().add(4, 'days').unix().toString();
        var dueDay = moment($('#newToDoDate').val()).unix().toString();

        if(dueDay < nowDay) { 
          newObj.when = 'earlier';
        }
        else {
          if(dueDay  > nowDayAnd4) { 
            newObj.when = 'later';
          }
          else {
            newObj.when = 'soon';
          }
        }

        $scope.todos.push(newObj);

        localStorateUpdateTodos($scope.todos);
      };
      
    $scope.updateToDo = function() {
      localStorateUpdateTodos($scope.todos);
    };

    $scope.updateToDoDate = function(index) {
        
        index = index;
        //console.log(index)

        //do a bit of jiggering here with the item date valiues and save as below
        /* values that need updating are:
        
        newObj.due_date = moment($('#newToDoDate').val()).format("dddd, MMMM Do YYYY, h:mm a");
        newObj.due_date_short = moment($('#newToDoDate').val()).format("MM/DD");
        newObj.due_date_editable = moment($('#newToDoDate').val()).format("YYYY-MM-DD");
        newObj.due_time_editable = $('#newToDoTime').val();
        newObj.due_date_sort = moment($('#newToDoDate').val()).unix();
        */
      
      localStorage.setItem('toDoStore', JSON.stringify(_.where($scope.todos, {origin: 'gt'}), function (key, val) {
         if (key == '$$hashKey') {
             return undefined;
         }
         if (key == 'when') {
             return undefined;
         }

         return val;
      }));
      

    };

    $scope.removeToDos = function() {
      for (var i = $scope.todos.length - 1; i >= 0; i--) {
        if ($scope.todos[i].checked) {
            $scope.todos.splice(i, 1);
        }
      }
      localStorateUpdateTodos($scope.todos);
      $('#removeToDos').fadeOut('slow');
    };

  });
  });  
}]);
