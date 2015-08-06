'use strict';
/* jshint  strict: true*/
/* global $*/

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

  var is_mobile = false;
  if( $('#isMobile').css('display')=='none') {
        is_mobile = true;
    }
  if(!is_mobile){
    var getImage = $.getJSON( "/data/images/back/list.json", function(data) {
    var ramdomImage = data[Math.floor(Math.random() * data.length) + 1  ];

    console.log(Math.random() * data.length + 1);
    console.log(ramdomImage);

    $('body').css('background-image','url("/data/images/back/' + ramdomImage);
    })
    .fail(function() {
      console.log(':(');
      // do nothing or load predetermined local image
    })
    .always(function() {
      // what
    });
  }

})