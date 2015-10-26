'use strict';
/* jshint  strict: true*/
/* global $, dashboardApp, _ */


/**
 * Dashboard Message Controller: determines what if anything to display in the mesage panel
 */

dashboardApp.controller('dashMessageController', ['DashMessage','$rootScope', '$scope',  function (DashMessage, $rootScope, $scope) {
    //use factory to fetch list of available text files if the user has not dismissed the alert that displays them
    //in this session
    if (!sessionStorage.getItem('dashMessageSeen')) {
      DashMessage.getMessageIndex('external/text/').then(function (data) {
        if (data.length === 0) {
          // make sure text container remains hidden, as there is nothing to show
          $scope.dashMessage = false;
        } else {
          // use underscore to select one element from the array
          var dashMessageRandom = _.sample(data);
          // use factory to retrieve text of this random file, and assign the contents to the scope
          DashMessage.getMessage('external/text/' + dashMessageRandom).then(function (data) {
            $scope.dashMessage = data;
          });
        }
      });
    }
}]);

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
  * Todo controller, using fake data for now
  */

dashboardApp.controller('todoController', ['ToDos', '$scope', '$rootScope', function(ToDos, $scope, $rootScope) {
  $scope.loadingToDos = true;
  ToDos.getToDos('/todolms/' + $rootScope.user).then(function(data) {
    $scope.loadingToDos = false;
    $scope.todos = data.combinedToDos;
    $scope.todoStatus = data.status;
    $scope.todo_time_options = [{
       name: 'Overdue',
       value: 'overdue'
    }, {
       name: 'Due today',
       value: 'today'
    }, {
       name: 'Due this week',
       value: 'week'
    }];

    $scope.showWhen = 'today';

    $scope.setWhen = function(when) {
       $scope.showWhen = when;
       $('#todo .itemList').attr('tabindex',-1).focus();
    };
  });
}]);
