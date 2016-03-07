'use strict';
/* jshint  strict: true*/
/* global $, dashboardApp, _, extractIds */


/**
 * Terms controller - Angular dependencies are injected.
 * It adds the terms to the scope and binds them to the DOM
 * 
 */
dashboardApp.controller('termsController', ['Courses', 'Terms', 'Schedule', '$rootScope', '$scope', '$log', function(Courses, Terms, Schedule, $rootScope, $scope, $log) {
    $scope.selectedTerm = null;
    $scope.terms = [];

    var termsUrl = 'terms';
    //use the Terms factory as a promise. Add returned data to the scope

    Terms.getTerms(termsUrl).then(function(data) {
        if (data.failure) {
            $scope.error = $rootScope.lang.termFailure;
        } else {
            // the ESB might return a single object rather than an array, turn it into an array
            if (data.Result.length === undefined) {
                data.Result = [].concat(data.Result);
            }
            if (data.Result.length !== 0) {

                $scope.terms = data.Result;
                $scope.$parent.term = data.Result[0].TermDescr;
                $scope.$parent.shortDescription = data.Result[0].TermShortDescr;
                $scope.$parent.termId = data.Result[0].TermCode;

                $scope.courses = [];
                $scope.loading = true;
                var url = 'courses/' + $rootScope.user + '.json?TERMID=' + $scope.$parent.termId;
                //use the Courses factory as a promise. Add returned data to the scope.

                Courses.getCourses(url).then(function(data) {
                    if (data.failure) {
                        $scope.courses.errors = data;
                        $scope.loading = false;
                    } else {
                        $scope.courses = data;
                        $scope.shareCanvasTitles = [];
                        //shareCanvas.setCanvasArray(extractIds(data));
                        $.each($scope.courses, function() {
                            if (this.source = 'Canvas' && this.Link) {
                                $scope.shareCanvasTitles.push({ 'id': _.last(this.Link.split('/')), 'title': this.Title + ' ' + this.SectionNumber });
                            }
                        })
                        Schedule.getSchedule('/todolms/' + $rootScope.user + '/canvas').then(function(data) {
                            $scope.loadingSchedule = false;
                            if (data.status === 200) {
                                $.each(data.data.Result, function() {
                                    var thisId = _.last(this.context.split('_'));
                                    this.context = null;
                                    var thisContext = _.findWhere($scope.shareCanvasTitles, { id: thisId });

                                    if (thisContext) {
                                        this.context = thisContext.title;
                                    } else {
                                        this.context = null;
                                    }
                                });

                                $scope.schedule = data.data.Result.concat($scope.schedule);
                            } else {
                                $scope.scheduleErrors.push({ 'status': data.status, 'message': 'Error getting upcoming assignments from Canvas' });
                            }
                        });
                        $scope.loading = false;
                    }
                    $('.colHeader small').append($('<span id="done" class="sr-only">' + $scope.courses.length + ' courses </span>'));
                });
            } else {
                $scope.$parent.term = 'You do not seem to have courses in any terms we know of.';
            }
        }
    });

    //Handler to change the term and retrieve the term's courses, using Course factory as a promise

    $scope.getTerm = function(termId, termName, shortDescription) {
        $scope.loading = true;
        $scope.courses = [];
        $scope.$parent.term = termName;
        $scope.$parent.shortDescription = shortDescription;

        var url = 'courses/' + $rootScope.user + '.json' + '?TERMID=' + termId;

        Courses.getCourses(url).then(function(data) {
            if (data.failure) {
                $scope.courses.errors = data;
                $scope.loading = false;
            } else {
                $scope.courses = data;
                $scope.loading = false;
            }
        });
    };

    $scope.loadingSchedule = true;
    $scope.schedule = [];
    $scope.schedule_time_options = [{
        name: 'Due last 7 days',
        value: 'overdue'
    }, {
        name: 'Due today',
        value: 'today'
    }, {
        name: 'Next 7 days',
        value: 'week'
    }];

    $scope.scheduleErrors = [];

    Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctools').then(function(data) {
        $scope.loadingSchedule = false;
        if (data.status === 200) {
            $scope.schedule = data.data.Result.concat($scope.schedule);
            // need to remove any dupes (since there is an overlap in data returned between ctools/dash/next and ctools/dash/past)
            $scope.schedule = _.uniq($scope.schedule, false, function(s) {
                return s.link;
            });
        } else {
            $scope.scheduleErrors.push({ 'status': data.status, 'message': 'Error getting upcoming assignments from CTools' });
        }
    });
    Schedule.getSchedule('/todolms/' + $rootScope.user + '/ctoolspast').then(function(data) {
        $scope.loadingSchedule = false;
        if (data.status === 200) {
            $scope.schedule = data.data.Result.concat($scope.schedule);
            // need to remove any dupes (since there is an overlap in data returned between ctools/dash/next and ctools/dash/past)
            $scope.schedule = _.uniq($scope.schedule, false, function(s) {
                return s.link;
            });
        } else {
            $scope.scheduleErrors.push({ 'status': data.status, 'message': 'Error getting past assignments from CTools' });
        }
    });
    Schedule.getSchedule('/todolms/' + $rootScope.user + '/mneme').then(function(data) {
        $scope.loadingSchedule = false;
        if (data.status === 200) {
            $scope.schedule = data.data.Result.concat($scope.schedule);
        } else {
            $scope.scheduleErrors.push({ 'status': data.status, 'message': 'Error getting Test Center items from CTools' });
        }
    });

    $scope.schedule_time_options = [{
        name: 'Due last 7 days',
        value: 'overdue'
    }, {
        name: 'Due today',
        value: 'today'
    }, {
        name: 'Next 7 days',
        value: 'week'
    }];


    $scope.showWhen = 'today';

    $scope.setWhen = function(when) {
        $scope.showWhen = when;
        $('#schedule .itemList').attr('tabindex', -1).focus();
    };
}]);
