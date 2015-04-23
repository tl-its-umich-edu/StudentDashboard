'use strict';
/* jshint  strict: true*/
/* global $, alert*/

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

var canvasToDoCleaner = function(result){
  var transformedData =[];
  $.each(result.data, function() {
    var newObj = {};
    newObj.title = this.title;
    newObj.due_date = moment(this.end_at).format("dddd, MMMM Do YYYY, h:mm a");
    newObj.due_date_short = moment(this.end_at).format("MM/DD");
    newObj.due_date_sort = moment(this.end_at, moment.ISO_8601).unix().toString();
    newObj.link = this.html_url;
    newObj.context = this.context_code;
    newObj.contextLMS = 'canvas';
    newObj.contextUrl = 'https://umich.test.instructure.com/courses/' + this.id;
    newObj.description = '';

    var nowDay = moment();
    var nowDayAnd4 = moment().add(4, 'days');
    var dueDay = moment(this.end_at);
    var dueDayAnd4 = moment(this.end_at).add(4, 'days')

    if(dueDay.isBefore(nowDay)) { 
      newObj.later = 'earlier';
    }
    else {
      if(dueDay.isAfter(nowDayAnd4) ) { 
        newObj.later = 'later';
      }
      else {
        newObj.later = 'now';
      }
    }
    if(this.assignment) {
      newObj.contextUrl = 'https://umich.test.instructure.com/courses/' + this.assignment.course_id;
      newObj.grade_type = this.assignment.grading_type;
      newObj.grade = this.assignment.points_possible;
    }
    transformedData.push(newObj)
  });

  return transformedData;

}

var ctoolsToDoCleaner = function(result){
  var transformedData =[];
  $.each(result.data.dash_collection, function() {
    var newObj = {};
    if (this.calendarItem.calendarTimeLabelKey ==='assignment.due.date' || this.calendarItem.calendarTimeLabelKey ==='assignment.close.date' ) {
      var siteInfo = this.calendarItem.context.contextUrl.split('portal/site');
      var siteInfoServer = siteInfo[0];
      var siteInfoId = siteInfo[2];
      newObj.title = this.calendarItem.title;
      newObj.due_date = moment.utc(this.calendarItem.calendarTime).format("dddd, MMMM Do YYYY, h:mm a");
      newObj.due_date_sort = this.calendarItem.calendarTime.toString().substr(0, 10);
      newObj.link = siteInfoServer + '/direct/assignment/deepLink/' + this.calendarItem.entityReference.replace('/assignment/a/','') + '.json';
      newObj.grade = '';
      newObj.done = '';
      newObj.context = this.calendarItem.context.contextTitle;
      newObj.contextUrl = this.calendarItem.context.contextUrl;
      newObj.contextLMS = 'ctools';
      newObj.descripion = '';
      
      var nowDay = moment();
      var nowDayAnd4 = moment().add(4, 'days');
      var dueDay = moment.utc(this.calendarItem.calendarTime);
      var dueDayAnd4 = moment.utc(this.calendarItem.calendarTime).add(4, 'days')

      if(dueDay.isBefore(nowDay)) { 
        newObj.later = 'earlier';
      }
      else {
        if(dueDay.isAfter(nowDayAnd4) ) { 
          newObj.later = 'later';
        }
        else {
          newObj.later = 'now';
        }
      }
      transformedData.push(newObj)
    }
  });
  return transformedData;
}

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

$(document).on('click', 'a.assigLinkctools', function (e) {
  e.preventDefault();
  var url = $(this).attr('href');
  alert('this would open the assignment in the site if the world were a just place')
  /* below does not work because of Cross-Origin Request - but it is the only 
  client side way of getting to the directtool enabled assignment, this will need to 
  happen at the servlet level

  var jqxhr = $.getJSON( url, function() {
    //open a window based on the return value's data.assignmentUrl
  })
  .fail(function() {
    //open a window based on the site URL as a fallback
  });
  */
  return null;
});
/**
 * Folowing handlers are for portions of the dashboard yet to be developed
 * So commented out
 */

$(document).on('click', '.mailTolink', function (e) {
  e.preventDefault();
  alert('This would take you to your email client to message ' + $(this).text());
  return null;
});

$(document).on('click', '#saveToDo', function () {
  var newitemtitle = $('#toDoTitle').val();
  var newitemmessage = $('#toDoMessage').val();
  var newId = Math.floor(Math.random() * 1001);
  $('<li class="container-fluid newToDo firstTime"><div class="row"><span class="noDueDate"></span><div class ="col-lg-1 col-md-1 col-xs-1 gt iconContainer"><span><input type="checkbox" id="todo' + newId + '"/></span></div><div class ="col-lg-7 col-md-7 col-xs-7"><label for="todo' + newId + '">' + newitemtitle + '</label><br><small><span>' + newitemmessage + '</span></small></div><div class ="col-lg-4 col-md-4 col-sm-4 col-xs-4 date"><small> </small></div></div></li>').appendTo('#todo ul');
  $('#newToDoModal').modal('hide');
  $('#toDoTitle').val('');
  $('#toDoMessage').val('');
  var $store = '';
  var $new = $('.newToDo');
  $.each($new, function () {
    var outer_html = $(this).clone().removeClass('firstTime').wrap('<p>').parent('p').html();
    $store = $store + outer_html;
  });
  localStorage.setItem('toDoStore', $store);
});


$(document).ready(function () {
  $(localStorage.getItem('toDoStore')).appendTo('#todo ul');
  $('body').popover({
    selector: '.popOver',
    placement: 'bottom',
    html: true
  });
});

$(document).on('click', '.popover', function () {
  $(this).popover('destroy');
});
$(document).on('click', '#todo input', function () {
  if ($('#todo input:checked').length) {
    $('#removeToDos').fadeIn();
  } else {
    $('#removeToDos').fadeOut();
  }
});
$(document).on('click', '#removeToDos', function () {

  var $store = '';

  var $removeList = $('.newToDo').find('input:checked').closest('li').remove();
  var $new = $('.newToDo');
  $.each($new, function () {
    var outer_html = $(this).clone().wrap('<div>').parent('div').html();
    $store = $store + outer_html;
  });
  localStorage.setItem('toDoStore', $store);
  $removeList.remove();
  $('#removeToDos').fadeOut();
});

$(document).on('click', '#selectTodos a', function (e) {
  e.preventDefault();
  var whatToDo = $(this).attr('id');

  $('#todo ul li').hide();

  if (whatToDo === 'selectUnscheduled') {
    $('.noDueDate').closest('li').show();
  }
  if (whatToDo === 'selectSheduled') {
    $('.dueDate').closest('li').show();
  }
  if (whatToDo === 'selectAll') {
    $('#todo ul li').show();
  }
});
$(document).on('click', '#showAllPanels', function () {
  //$('.phasePlusOne').toggle();
});
