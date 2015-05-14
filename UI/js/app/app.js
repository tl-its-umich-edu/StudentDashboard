'use strict';
/* jshint  strict: true*/
/* global $, angular */

var dashboardApp = angular.module('dashboardApp', ['dashFilters']);
/**
 * Initialize Angular app with the user id and the strings file
 */

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
  $rootScope.lang = JSON.parse($('#lang').text());
});
