'use strict';
/* jshint  strict: true*/
/* global $, angular */

var dashboardApp = angular.module('dashboardApp', ['ngAnimate','dashFilters','xeditable','ngSanitize']);
/**
 * Initialize Angular app with the user id and the strings file
 */

dashboardApp.run(function ($rootScope) {
  $rootScope.user = $('#userId').text();
  $rootScope.lang = JSON.parse($('#lang').text());
});


dashboardApp.run(function(editableOptions, editableThemes) {
  editableThemes.bs3.inputClass = 'input-xs';
  editableThemes.bs3.buttonsClass = 'btn-xs';
  editableOptions.theme = 'bs3';
});
