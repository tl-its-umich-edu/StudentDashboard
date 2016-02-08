'use strict';
/* jshint  strict: true*/
/* global $, dashboardApp, _ */


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
      $scope.error  = $rootScope.lang.termFailure;
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
            $rootScope.$broadcast('canvasCourses', extractIds(data));
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

dashboardApp.controller('scheduleController', ['Schedule', '$scope', '$rootScope', function(Schedule, $scope, $rootScope) {
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

  Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctools').then(function(data) {
    $scope.loadingSchedule = false;
    if(data.status ===200){
      $scope.schedule = data.data.Result.concat($scope.schedule);
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'source':'ctools'});
    }
  });
  Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctoolspast').then(function(data) {
    $scope.loadingSchedule = false;
    if(data.status ===200){
      $scope.schedule = data.data.Result.concat($scope.schedule);
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'source':'ctoolspast'});
    }
  });
  Schedule.getSchedule('/todolms/' + $rootScope.user + '/mneme').then(function(data) {
    $scope.loadingSchedule = false;
    if(data.status ===200){
      $scope.schedule = data.data.Result.concat($scope.schedule);
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'source':'mneme'});
    }
  });
  Schedule.getSchedule('/todolms/' + $rootScope.user + '/canvas').then(function(data) {
    $scope.loadingSchedule = false;
    if(data.status ===200){
      $scope.schedule = data.data.Result.concat($scope.schedule);
    } else {
      $scope.scheduleErrors.push({'status':data.status, 'source':'ctoolspast'});
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

   $scope.$on('canvasCourses', function (event, canvasCourses) {
      //listen for changes to the Canvas course array (created by the Courses controller)
      // and match the course title of the Canvas assignments to the course title in the array
      $.each($scope.schedule, function() {
        if(this.contextLMS === 'canvas'){
          var thisId = _.last(this.contextUrl.split('/'));
          var thisContext = _.findWhere(canvasCourses, {id: thisId});
          if(thisContext){
            this.context = thisContext.title;
          }
          else {
            this.context = null;
          }
        }
    });
  });

    $scope.showWhen = 'today';

    $scope.setWhen = function(when) {
       $scope.showWhen = when;
       $('#schedule .itemList').attr('tabindex',-1).focus();
    };



}]);
