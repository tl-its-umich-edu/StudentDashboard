// round dates to reasonable boundries
// expects dates as epoch times

function DateRound() {
}

//DateRound.prototype.roundSecond = function (epoch) {
DateRound.roundSecond = function (epoch) {
    //make date and then zero out settings less than second
    d = new Date();
    d.setTime(epoch);
    d.setMilliseconds(0);
    return d;
};

DateRound.roundMinute = function (epoch) {
    //make date and then zero out settings less than minute
    d = new Date();
    d.setTime(epoch);
    d.setSeconds(0,0);
    return d;
};

DateRound.roundHour = function (epoch) {
    //make date and then zero out settings less than hour
    d = new Date();
    d.setTime(epoch);
    d.setMinutes(0,0,0);
    return d;
};

DateRound.roundDay = function (epoch) {
    //make date and then zero out settings less than a day
    // do it in local time
    d = new Date();
    d.setTime(epoch);
    // sethours considers timezone. setUTCHours doesn't
    d.setUTCHours(0,0,0,0)
    return d;
};
