'use strict';
/* jshint  strict: true*/
/* global $, dashboardApp */

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
