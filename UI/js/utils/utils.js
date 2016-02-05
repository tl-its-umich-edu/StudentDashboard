'use strict';
/* jshint  strict: true*/
/* global $, _, moment*/

/**
 * get the strings from a hidden DOM element and
 * evaluate so that it is available to the non-Angular js
 */
var lang = JSON.parse($('#lang').text());

/**
 * Show spinner whenever ajax activity starts
 */
$(document).ajaxStart(function() {
  $('#spinner').show();
});

/**
 * Hide spinner when ajax activity stops
 */
$(document).ajaxStop(function() {
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
var errorHandler = function(url, result) {
  var errorResponse = {};
  if (!result) {
    errorResponse.message = 'Something happened!';

  } else {
    errorResponse.message = lang.errorCourses;
  }
  return errorResponse;

};

var statusResolver = function(status, count) {
  var message;
 
 switch (status) {
  case 200:
    message = '- all is well';
    break;
  case 400:
    message = '- bad request';
    break;
  case 401:
    message = '- not authorized';
    break;
  case 403:
    message = '- forbidden';
    break;
  case 404:
    message = '- not found';
    break;
  case 408:
    message = '- request timeout';
    break;
  case 500:
    message = '- internal Server Error';
    break;
  case 504:
    message = '- gateway Timeout';
    break;
  case 666:
    message = '- demonic possession';
    break;
  default:
    message = '- status not accounted for';
  }
  return {
    'status': status,
    'message': message,
    'count': count
  };
};


var prepareSchedule = function(result) {
  var combinedScheduleAndStatus = {
    'status': {
      'ctools': statusResolver(result.data.ctools.Meta.httpStatus, result.data.ctools.Result.length),
      'canvas': statusResolver(result.data.canvas.Meta.httpStatus, result.data.canvas.Result.length)
    },
    'combinedSchedule': []
  };

  var combinedSchedule = result.data.ctools.Result.concat(result.data.canvas.Result);
  if(combinedSchedule.length){
    $.each(combinedSchedule, function() {
      this.due_date_sort = parseInt(this.due_date_sort);
      this.due_date_long = moment.unix(this.due_date_sort).format('dddd, MMMM Do YYYY, h:mm a');
      this.due_date_medium = moment.unix(this.due_date_sort).format('MM/DD/YY h:mm a');
      this.due_date_short = moment.unix(this.due_date_sort).format('MM/DD');
      this.due_date_time = moment.unix(this.due_date_sort).format('h:mm a');

      var now = moment();
      var due = moment(this.due_date_sort * 1000);

      if (due < now) {
        this.when = 'overdue';
      }

      if (now.isSame(due, 'd')) {
        this.when = 'today';
      }

      // better for week - but still needs to incorporate todays items
      if ((due.diff(now, 'days') > 0) && (due.diff(now, 'days') < 7)) {  
        this.when = 'week';
      }
    });
    combinedScheduleAndStatus.combinedSchedule = _.sortBy(combinedSchedule, 'due_date_sort');
  } else {
    combinedScheduleAndStatus.combinedSchedule = [];
  } 

  return combinedScheduleAndStatus;
};

var extractIds = function(data){
  var canvasCourses=[];
  var thisObj ={}
  $.each(data, function() {
    if(this.Source ==='Canvas'){
      thisObj= {'id': _.last(this.Link.split('/')),'title':this.Title + ' ' + this.SectionNumber}
      canvasCourses.push(thisObj)
    }
  });
  return canvasCourses;
}

/**
 *
 * event watchers
 */

/**
 * All instructors are hidden save the first primary instructor (by alphanum), or the first alphanum.
 * Handler below toggles the complete list
 */
$(document).on('click', '.showMoreInstructors', function(e) {
  e.preventDefault();
  var txt = $(this).closest('div.instructorsInfo').find('.moreInstructors').is(':visible') ? '(more)' : '(less)';
  $(this).text(txt);
  $(this).closest('div.instructorsInfo').find('.moreInstructors').fadeToggle();
  return null;
});

$(document).ready(function() {
  // determine size of viewport
  var is_mobile;
  if ($('#isMobile').is(':visible') === false) {
    is_mobile = true;
  } else {
    is_mobile = false;
  }
  // if not a small viewport fetch a list of the available background images
  if (!is_mobile) {
    $.ajax({
      url: 'external/image',
      cache: true,
      dataType: 'json',
      method: 'GET'
    })
    .done(function(data){
      // pick a random image and assign it to the body element
      var ramdomImage = _.sample(data);
      document.body.style.backgroundImage = 'url(external/image/' + ramdomImage + ')';      
    })
    .fail(function() {
      // select a default image and assign it to the body element
      document.body.style.backgroundImage = 'url(data/images/back/default.jpg)';
    });
  }
});

