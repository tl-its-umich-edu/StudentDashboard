'use strict';
/* jshint  strict: true, unused:false, eqnull:true */
/* global $, moment, _ */

/**
 * get the strings from a hidden DOM element and
 * evaluate so that it is available to the non-Angular js
 */
var lang = JSON.parse($('#lang').text());

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

/**
 * takes a standard Canvas todo json and normalizes it for consumption by
 * the todo panel
 */

var canvasToDoCleaner = function(result){
  var transformedData =[];
  $.each(result.data, function() {
    var newObj = {};
    newObj.title = this.title;
    newObj.due_date = moment(this.end_at).format('dddd, MMMM Do YYYY, h:mm a');
    newObj.due_date_short = moment(this.end_at).format('MM/DD');
    newObj.due_date_sort = moment(this.end_at, moment.ISO_8601).unix().toString();
    newObj.link = this.html_url;
    newObj.context = this.context_code;
    newObj.contextLMS = 'canvas';
    newObj.contextUrl = 'https://umich.test.instructure.com/courses/' + this.id;
    newObj.description = '';

    var nowDay = moment();
    var nowDayAnd4 = moment().add(4, 'days');
    var dueDay = moment(this.end_at);

    if(dueDay.isBefore(nowDay)) { 
      newObj.when = 'earlier';
    }
    else {
      if(dueDay.isAfter(nowDayAnd4) ) { 
        newObj.when = 'later';
      }
      else {
        newObj.when = 'soon';
      }
    }

    if(this.assignment) {
      newObj.contextUrl = 'https://umich.test.instructure.com/courses/' + this.assignment.course_id;
      newObj.grade_type = this.assignment.grading_type;
      newObj.grade = this.assignment.points_possible;
    }
    transformedData.push(newObj);
  });

  return transformedData;

};

/**
 * takes a standard CTools dashboard schedule feed json and normalizes it for consumption by
 * the todo panel
 */


var ctoolsToDoCleaner = function(result){
  var transformedData =[];
  $.each(result.data.dash_collection, function() {
    var newObj = {};
    if (this.calendarItem.calendarTimeLabelKey ==='assignment.due.date' || this.calendarItem.calendarTimeLabelKey ==='assignment.close.date' ) {
      var siteInfo = this.calendarItem.context.contextUrl.split('portal/site');
      var siteInfoServer = siteInfo[0];
      newObj.title = this.calendarItem.title;
      newObj.due_date = moment.utc(this.calendarItem.calendarTime).format('dddd, MMMM Do YYYY, h:mm a');
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

      if(dueDay.isBefore(nowDay)) { 
        newObj.when = 'earlier';
      }
      else {
        if(dueDay.isAfter(nowDayAnd4) ) { 
          newObj.when = 'later';
        }
        else {
          newObj.when = 'soon';
        }
      }
      transformedData.push(newObj);
    }
  });
  return transformedData;
};

/**
 * Gets passed a Google tasks json tasklist representation
 * and normalizes it for the todo panel
 */

var GTasksToDoCleaner = function(result){
  var transformedData =[];
  $.each(result, function() {
    var newObj = {};
    newObj.title = this.title;
    newObj.origin ='gt';
    newObj.message = this.message;
    if(this.due_date){
      newObj.due_date = this.due_date;
      newObj.due_date_short = this.due_date_short;
      newObj.due_date_sort = this.due_date_sort;
      newObj.due_date_editable = this.due_date_editable;
      newObj.due_time_editable = this.due_time_editable;
      var nowDay = moment().unix().toString();
      var nowDayAnd4 = moment().add(4, 'days').unix().toString();
      var dueDay = moment(this.due_date_sort).unix().toString();
      if(dueDay < nowDay) { 
        newObj.when = 'earlier';
      }
      else {
        if(dueDay  > nowDayAnd4) { 
          newObj.when = 'later';
        }
        else {
          newObj.when = 'soon';
        }
      }
    } else {
      newObj.when = 'nodate';
    }  

    transformedData.push(newObj);
  
  });
  return transformedData;
};

/**
 * Save user added todos to localStorage (used when todo is added, edited, or deleted)
 */

var localStorateUpdateTodos = function(data) {
  localStorage.setItem('toDoStore', JSON.stringify(_.where(data, {origin: 'gt'}), function (key, val) {
     //strip Angular state info and the when value before storing
     if (key == '$$hashKey') {
         return undefined;
     }
     if (key == 'when') {
         return undefined;
     }
     return val;
  }));
};
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


$(document).on('click', '#addToDo', function () {
  $('#quickAddTask').focus()
});

$('#newToDoModal').on('hide.bs.modal', function (e) {
  $('#toDoTitle, #newToDoDate, #newToDoTime, #toDoMessage').val('');
})

$('#newToDoModal').on('hidden.bs.modal', function (e) {
  $('#toDoTitle, #newToDoDate, #newToDoTime, #toDoMessage').val('');
})