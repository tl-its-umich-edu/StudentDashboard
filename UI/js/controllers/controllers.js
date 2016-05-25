'use strict';
/* jshint  strict: true*/
/* global $, dashboardApp, _, moment*/


/**
 * Terms controller - Angular dependencies are injected.
 * It adds the terms to the scope and binds them to the DOM
 *
 */
dashboardApp.controller('termsController', ['Courses', 'Terms', 'Schedule', 'canvasShare', '$rootScope', '$scope', '$log', function (Courses, Terms, Schedule, canvasShare, $rootScope, $scope, $log) {
  $scope.selectedTerm = null;
  $scope.terms = [];

  var termsUrl = 'terms';
  //use the Terms factory as a promise. Add returned data to the scope

  Terms.getTerms(termsUrl).then(function (data) {
    if (data.failure) {
      $scope.error  = true;
      $rootScope.termError = true;
    }
    else {
      // the ESB might return a single object rather than an array, turn it into an array
      if (data.Result.length === undefined ){
        data.Result = [].concat(data.Result);
      }
      if (data.Result.length !==0)  {

        $scope.terms = data.Result;
        $scope.$parent.term = data.Result[0].TermDescr;
        $scope.$parent.shortDescription = data.Result[0].TermShortDescr;
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
            var shareArr = [];
            $.each(data, function() {
              if(this.Source ==='Canvas' && this.Link) {
                var thisId = _.last(this.Link.split('/'));
                var thisTitle = this.Title;
                shareArr.push({'id': thisId, 'title':thisTitle})
              }
            });

            Schedule.getSchedule('/todolms/' + $rootScope.user + '/canvas.json').then(function(data) {
              if(data.status ===200){
                $.each(data.data.Result, function() {
                    var thisId = _.last(this.contextUrl.split('/'));
                    var thisContext = _.findWhere(shareArr, {id: thisId});
                    if(thisContext){
                      this.context = thisContext.title;
                    }
                    else {
                      this.context = null;
                    }
                });
                canvasShare.sendData(data);
              } else {
                canvasShare.sendData({'status':data.status, 'message':'Error getting upcoming assignments from Canvas'});
              }
            });
          }
          $('.colHeader small').append($('<span id="done" class="sr-only">' + $scope.courses.length + ' courses </span>'));
        });
      } else {
        $scope.$parent.term  = 'You do not seem to have courses in any terms we know of.';
      }
    }
  });

  //Handler to change the term and retrieve the term's courses, using Course factory as a promise

  $scope.getTerm = function (termId, termName, shortDescription) {
    $scope.loading = true;
    $scope.courses = [];
    $scope.$parent.term = termName;
    $scope.$parent.shortDescription = shortDescription;

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
  * Schedule controller
  */

dashboardApp.controller('scheduleController', ['Schedule', 'canvasShare', '$scope', '$rootScope', '$log', function(Schedule, canvasShare, $scope, $rootScope, $log) {
  $scope.loadingSchedule = true;
  $scope.schedule =[];
  $scope.schedule_time_options = [{
     name: 'Due last 7 days',
     value: 'overdue'
  }, {
     name: 'Due today',
     value: 'today'
  }, {
     name: 'Next 7 days',
     value: 'week'
  }];

  $scope.scheduleErrors=[];

  Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctools.json').then(function(data) {
    if(data.status ===200){
      $scope.loadingSchedule = false;
      $.each(data.data.Result, function (i, l) {
        if(!_.findWhere($scope.schedule, {link: l.link, title:l.title, due_date_sort:l.due_date_sort})){
          $scope.schedule.push(l);
        }  
      });
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'message':'Error getting upcoming assignments from CTools'});
    }
  });
  Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctoolspast.json').then(function(data) {
    if(data.status ===200){
      $scope.loadingSchedule = false;
      $.each(data.data.Result, function (i, l) {
        if(!_.findWhere($scope.schedule, {link: l.link, title:l.title, due_date_sort:l.due_date_sort})){
          $scope.schedule.push(l);
        }  
      });
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'message':'Error getting past assignments from CTools'});
    }
  });
  Schedule.getSchedule('/todolms/' + $rootScope.user + '/mneme.json').then(function(data) {
    if(data.status ===200){
      $scope.loadingSchedule = false;
      $scope.schedule = data.data.Result.concat($scope.schedule);
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'message':'Error getting Test Center items from CTools'});
    }
  });

  $scope.$on('canvas_shared',function(){
    $scope.loadingSchedule = false;
    var canvasArray =  canvasShare.getData();
    if(canvasArray.status ===200){
      $scope.schedule = canvasArray.data.Result.concat($scope.schedule);
    }
    else {
      $scope.scheduleErrors.push({'status':canvasArray.status, 'message':'Error getting upcoming assignments from Canvas'});
    }
  });


    $scope.schedule_time_options = [{
       name: 'Due last 7 days',
       value: 'overdue'
    }, {
       name: 'Due today',
       value: 'today'
    }, {
       name: 'Next 7 days',
       value: 'week'
    }];


    $scope.showWhen = 'today';

    $scope.setWhen = function(when) {
       $scope.showWhen = when;
       $('#schedule .itemList').attr('tabindex',-1).focus();
    };



}]);
