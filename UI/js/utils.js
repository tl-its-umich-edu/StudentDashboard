/**
 * Show spinner whenever ajax activity starts
 */
$(document).ajaxStart(function(){
    $('#spinner').show();
});

/**
 * Hide spinner when ajax activity stops
 */
$(document).ajaxStop(function(){
    $('#spinner').hide();
});

/**
 * set up global ajax options
 */
$.ajaxSetup({
    type: "GET",
    dataType: "json",
    cache: false
});

/**
 *
 * event watchers
 */
//$(document).on('click', '#schedule a', function(){});

$(document).on('click', '.courseLink', function(e){
    e.preventDefault();
    alert('This would take you to the course site for ' + $(this).text())
    return null;
});

$(document).on('click', '.mailTolink', function(e){
    e.preventDefault();
    alert('This would take you to your email client to message ' + $(this).text())
    return null;
});

$(document).on('click', '#saveToDo', function(e){
    var newitemtitle = $('#toDoTitle').val();
    var newitemmessage = $('#toDoMessage').val();
    var newId = Math.floor(Math.random()*1001);
    $('<li class="container-fluid newToDo firstTime"><div class="row"><span class="noDueDate"></span><div class ="col-lg-1 col-md-1 col-xs-1 gt iconContainer"><span><input type="checkbox" id="todo' + newId +'"/></span></div><div class ="col-lg-7 col-md-7 col-xs-7"><label for="todo' + newId + '">' + newitemtitle + '</label><br><small><span>' + newitemmessage + '</span></small></div><div class ="col-lg-4 col-md-4 col-sm-4 col-xs-4 date"><small> </small></div></div></li>').appendTo('#todo ul');
    $('#newToDoModal').modal('hide');
    $('#toDoTitle').val('');
    $('#toDoMessage').val('');
    var $store = '';
    var $new = $('.newToDo')
    $.each($new, function(){
        var outer_html = $(this).clone().removeClass('firstTime').wrap('<p>').parent('p').html();
        $store = $store + outer_html;
    });
    localStorage.setItem('toDoStore', $store);
});


$(document).ready(function(){
    $(localStorage.getItem('toDoStore')).appendTo('#todo ul');
    $('body').popover({
        selector: '.popOver',
        placement: 'bottom',
        html:true
    });
});

$(document).on('click', '.popover', function(e){
    $(this).popover('destroy');
});
$(document).on('click', '#todo input', function(e){
    if ($('#todo input:checked').length) {
        $('#removeToDos').fadeIn();
    }
    else {
        $('#removeToDos').fadeOut();
    }
})
$(document).on('click', '#removeToDos', function(e){

    var $store = '';
    
    var $removeList = $('.newToDo').find('input:checked').closest('li').remove();
    var $new = $('.newToDo');
    $.each($new, function(){
        var outer_html = $(this).clone().wrap('<div>').parent('div').html();
        $store = $store + outer_html;
    });
    localStorage.setItem('toDoStore', $store);
    $removeList.remove;
    $('#removeToDos').fadeOut();
});

$(document).on('click', '#selectTodos a', function(e){
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
