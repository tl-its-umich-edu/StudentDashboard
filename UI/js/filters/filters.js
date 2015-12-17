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
      if (when.diff(now, 'days') === 0){
        return when.from(now);
      }
      else {
        return (when.format('dddd h:mm a'))  
      }
      //return when.from(now);
      
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
}).filter('headerText', function() {
    return function(str) {
      switch (str) {
        case 'overdue':
          return 'Due Last 7 Days ';
        case 'week':
          return 'Due Next 7 Days';
        case 'today':
          return 'Due Today';
        default:
          return '';
      }

    };
}).filter('noItemsFoundForTime', function() {
    return function(str) {
      switch (str) {
        case 'overdue':
          return 'No overdue items.';
        case 'week':
          return 'No items due this week.';
        case 'today':
          return 'No items due today.';
        default:
          return '';
      }
    };
}).filter('showMeetingIfNow', function() {
    return function (meetings) {
    var filtered = [];
    var now = moment();
    for (var i = 0; i < meetings.length; i++) {
      var meeting = meetings[i];
      //if (moment(meeting.StartDate).isBefore(now) && moment(meeting.EndDate).add(10, 'days').isAfter(now)){
      if (moment(meeting.StartDate).isBefore(now) && moment(meeting.EndDate).isAfter(now)){
        filtered.push(meeting);
      }
    }
    return filtered;
  };
}).filter('fixMeetingDays', function () {
  return function (input) {
    if (input) {
      var strDays='';
      var arrayDays=[];
      var mapDays = {
         Mo:'Monday',
         Tu:'Tuesday',
         We:'Wednesday',
         Th:'Thursday',
         Fr: 'Friday',
         Sa: 'Saturday',
         Su: 'Sunday'
      };
      strDays = input.replace(/Mo|Tu|We|Th|Fr|Sa|Su/gi, function(matched){
        arrayDays.push(mapDays[matched]);
      });
      return arrayDays.join(', ');
    }
  };
});
