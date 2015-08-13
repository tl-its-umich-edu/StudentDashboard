'use strict';
/* jshint  strict: true*/
/* global $, _*/

/**
 * get the strings from a hidden DOM element and
 * evaluate so that it is available to the non-Angular js
 */
var lang = JSON.parse($('#lang').text());

/**
 * Show spinner whenever ajax activity starts
 */
$(document).ajaxStart(function () {
  $('#spinner').show();
});

/**
 * Hide spinner when ajax activity stops
 */
$(document).ajaxStop(function () {
  $('#spinner').hide();
});

/**
 * set up global ajax options
 */
$.ajaxSetup({
  type: 'GET',
  dataType: 'json',
  cache: false
});

/**
 * Generic error handler
 */
var errorHandler = function (url, result) {
  var errorResponse = {};
  if (!result) {
    errorResponse.message = 'Something happened!';

  } else {
    errorResponse.message = lang.errorCourses;
  }
  return errorResponse;

};


$('.dashMessage').bind('closed.bs.alert', function () {
  //here is where we do some localStorage or sessionStorage thing to make the dismissable stick
});

/**
 *
 * event watchers
 */

/**
 * All instructors are hidden save the first primary instructor (by alphanum), or the first alphanum.
 * Handler below toggles the complete list
 */
$(document).on('click', '.showMoreInstructors', function (e) {
  e.preventDefault();
  var txt = $(this).closest('div.instructorsInfo').find('.moreInstructors').is(':visible') ? '(more)' : '(less)';
  $(this).text(txt);
  $(this).closest('div.instructorsInfo').find('.moreInstructors').fadeToggle();
  return null;
});

$(document).ready(function(){
  // determine size of viewport
  var is_mobile;
  if( $('#isMobile').is(':visible') === false) {
    is_mobile = true;
  }
  else {
    is_mobile = false;
  }
  // if not a small viewport fetch a list of the available background images
  if(!is_mobile){
    $.ajax({
      url: '/external/image',
      cache: true,
      dataType: 'json',
      method: 'GET'
    })
    .done(function(data){
      // pick a random image and assign it to the body element
      var ramdomImage = _.sample(data);
      $('body').css('background-image','url("/external/image/' + ramdomImage);
    })
    .fail(function() {
      // select a default image and assign it to the body element
      $('body').css('background-image','url("/data/images/back/default.jpg');
    });
  }
});