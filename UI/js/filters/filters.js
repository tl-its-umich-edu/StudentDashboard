'use strict';
/* jshint  strict: true*/
/* global moment, angular */

/**
 * Collection of filters used to massage $scope elements
 * for display
 */

angular.module('dashFilters', []).filter('dateAgo', function () {
  return function (input) {
    var when = moment.unix(input);
    var now = moment();

    if (now.diff(when, 'days') < 2) {
      return moment.unix(input).fromNow();
    } else {
      return moment(when).format('MM/D');
    }
  };
}).filter('dateUntil', function () {
  return function (input) {
    if (input === '') {
      return '';
    }
    var when = moment.unix(input);
    var now = moment();
    if (when.diff(now, 'days') < -3 || when.diff(now, 'days') > 7) {
      return moment(when).format('MM/D');
    } else {
      return when.from(now);
    }
  };
}).filter('fixInstructorName', function () {
  return function (input) {
    if (input) {
      return input.replace(',', ', ');
    }
  };
}).filter('cut', function () {
  return function (value, wordwise, max, tail) {
      if (!value) return '';

      max = parseInt(max, 10);
      if (!max) return value;
      if (value.length <= max) return value;

      value = value.substr(0, max);
      if (wordwise) {
          var lastspace = value.lastIndexOf(' ');
          if (lastspace != -1) {
              value = value.substr(0, lastspace);
          }
      }
      return value + (tail || ' …');
  };
}).filter('fixClassTimes', function () {
  return function (input) {
    if (input) {
      return input.replace('-', '<br>');
    }
  };
}).filter('trustAsHtml', ['$sce', function($sce){
    return function(text) {
        return $sce.trustAsHtml(text);
    };
}]).filter('headerText', function() {
    return function(str) {
      switch (str) {
        case 'nodate':
          return 'No Date Specified'
        case 'earlier':
          return 'Due Earlier'
        case 'later':
          return 'Due Later'
        case 'soon':
          return 'Due Soon'
        default:
          return 'Default message.'
      }

    };
}).filter('noItemsFoundForTime', function() {
    return function(str) {
      switch (str) {
        case 'nodate':
          return 'No items without date found.'
        case 'earlier':
          return 'No earlier items found.'
        case 'later':
          return 'No later items found.'
        case 'soon':
          return 'No items due soon found.'
        default:
          return 'Default message.'
      }
    };
});

