'use strict';
/* jshint  strict: true*/
/* global dashboardApp, angular, $ */


dashboardApp.directive('expandText', function() {
  return {
    restrict: 'A',
    link: function(scope, elem, attrs) {
      var text =  $.trim(angular.element(elem).text());
      angular.element(elem).text(trunc(attrs.expandText, text, true));
      angular.element(elem).append('<a href="" class="expand"><small> (more...) </small></a>');
      
      angular.element(elem).children('a.expand').on('click', function() {
        elem.text(text);
      });
      
      function trunc(n, text, useWordBoundary) {
        var toLong = text.length > n,
          s_ = toLong ? text.substr(0, n-1) : text;
          s_ = useWordBoundary && toLong ? s_.substr(0, s_.lastIndexOf(' ')) : s_;
        return s_;
      }
    }
  };
});