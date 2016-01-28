describe("DateRound", function() {
  var dateRound;

  //beforeEach(function() {
  //  dateRound = new DateRound();
  //});

  //it("should be able to round a minute with small numbers", function() {
  //    d = dateRound.roundMinute(100*1000);
  //    //expect(dateRound.roundMinute(100)).toEqual(60);
  //    expect(d).toEqual(60*1000);
  //    console.log(new Date(d).toISOString());
  //
  //    d = dateRound.roundMinute(120*1000);
  //    expect(d).toEqual(120*1000);
  //    console.log(new Date(d).toISOString());
  //});


    it("should be able to round to a minute with recent times", function() {
        recent = new Date("2015-07-13T07:10:17.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundMinute(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:10:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    it("should be able to round to a minute with recent times 59 seconds", function() {
        recent = new Date("2015-07-13T07:10:59.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundMinute(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:10:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    it("should be able to round to a minute with recent times milliseconds", function() {
        recent = new Date("2015-07-13T07:10:59.555Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundMinute(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:10:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });


    it("should be able to round to the same exact minute", function() {
        recent = new Date("2015-07-13T07:10:00.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundMinute(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:10:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    it("should be able to round just over a minute", function() {
        recent = new Date("2015-07-13T07:11:01.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundMinute(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:11:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });


    it("should be able to round Hour (discard minutes)", function() {
        recent = new Date("2015-07-13T07:10:01.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundHour(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:00:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    it("should be able to round Day (discard hours)", function() {
        recent = new Date("2015-07-13T07:10:01.000Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundDay(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T00:00:00.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    it("should be able to round seconds (discard milliseconds)", function() {
        recent = new Date("2015-07-13T07:10:01.123Z");
        console.log("recent:  "+recent.toISOString() + " " + recent.getTime());

        rounded = DateRound.roundSecond(recent.getTime());
        d2 = new Date(rounded);
        console.log("rounded: "+d2.toISOString() + " " + d2.getTime());

        right = new Date("2015-07-13T07:10:01.000Z");
        console.log("right:   "+right.toISOString() + " " + right.getTime());
        expect(d2.getTime()).toEqual(right.getTime());

    });

    //describe("when song has been paused", function() {
  //  beforeEach(function() {
  //    player.play(song);
  //    player.pause();
  //  });
  //
  //  it("should indicate that the song is currently paused", function() {
  //    expect(player.isPlaying).toBeFalsy();
  //
  //    // demonstrates use of 'not' with a custom matcher
  //    expect(player).not.toBePlaying(song);
  //  });
  //
  //  it("should be possible to resume", function() {
  //    player.resume();
  //    expect(player.isPlaying).toBeTruthy();
  //    expect(player.currentlyPlayingSong).toEqual(song);
  //  });
  //});
  //
  //// demonstrates use of spies to intercept and test method calls
  //it("tells the current song if the user has made it a favorite", function() {
  //  spyOn(song, 'persistFavoriteStatus');
  //
  //  player.play(song);
  //  player.makeFavorite();
  //
  //  expect(song.persistFavoriteStatus).toHaveBeenCalledWith(true);
  //});
  //
  ////demonstrates use of expected exceptions
  //describe("#resume", function() {
  //  it("should throw an exception if song is already playing", function() {
  //    player.play(song);
  //
  //    expect(function() {
  //      player.resume();
  //    }).toThrowError("song is already playing");
  //  });
  //});
});
