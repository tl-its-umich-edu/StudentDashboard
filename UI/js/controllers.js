var dashboardApp = angular.module('dashboardApp', ['dashFilters']);

var userId = $('#userId').text();

dashboardApp.controller('scheduleController', ['$scope', '$http', function($scope, $http){
    var url = 'data/sched.json';
    $http.get(url).success(function(data){
        $scope.schedule = data;
    });
}
]);

dashboardApp.controller('coursesController', ['$scope', '$http', function($scope, $http, errorHttpInterceptor){
    var url = 'courses/' + userId + '.json';
    $scope.courses = [];
    //for testing
    //var url = 'data/courses/no-courses.json';
    $http.get(url).success(function(data){
        $scope.courses = data;
        if (!data.length){
            $scope.courses.message ="You seem to have no courses this term.";
        }       

		if (_.where(data, {
            Source: "CTools"
        }).length > 0 ) {
            $scope.courses.ctools = true;
        }
        if (_.where(data, {
            Source: "Canvas"
        }).length > 0) {
            $scope.courses.canvas = true;
        }
    }).error(function(data, status, headers, config) {
        $scope.courses.errors = errorHandler(url, data, status, headers, config);
  });
}
]);

dashboardApp.controller('todoController', ['$scope', '$http', function($scope, $http){
    var url = 'data/todo.json';
    
    $http.get(url).success(function(data){
        $scope.todos = data;
        $scope.isOverdue = function(item){
            //return item.due;
            var when = moment.unix(item.due);
            var now = moment();
            if (when < now) {
                return 'overdue';
            }
        }
    });
}
]);

dashboardApp.controller('eventsController', ['$scope', '$http', function($scope, $http){
    var url = 'data/events.json';
    $http.get(url).success(function(data){
        $scope.events = data;
    });
}
]);

dashboardApp.controller('uniEventsController', ['$scope', '$http', function($scope, $http){
    var url = 'data/uniWeekEvents.json';
    //var url = 'data/uniEvents.json';
    var url = 'https://events.umich.edu/week/json'
    $http.get(url).success(function(data){
        $scope.unievents = data;
    });
}
]);
