'use strict';
/* jshint  strict: true*/
/* global dashboardApp */

/**
 * Used to bind a function to the Enter key in th element it is used on
 */

dashboardApp.directive('ngEnter', function() {
  return function(scope, element, attrs) {
    element.bind('keydown keypress', function(event) {
      if (event.which === 13) {
        scope.$apply(function() {
          scope.$eval(attrs.ngEnter);
        });

        event.preventDefault();
      }
    });
  };
});