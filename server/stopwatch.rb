class Stopwatch

  # Add methods to stop / start timing.

  def initialize(name)
    reset(name)
  end

  # null out the stopwatch data
  def reset(name)
    # starting and end times for the current interval
    # end of current interval
    @end = nil
    # start of currently running interval or nil if there isn't one.
    @start = nil
    # elapsed time outside of the current interval.  E.g. might pause and restart.
    @elapsed = 0
    # number of events in the full elapsed interval.
    @events = 0
    # set name for stopwatch
    @name = name
  end

# Start timing
  def start()
    @start = Time.now
  end

  # stop the timing and return elapsed time for
  # the latest run.
  def stop()
    @end = Time.now
    current_elapsed = @end - @start
    @elapsed = @elapsed + current_elapsed
    @start = nil
    @elapsed
  end

  # show elapsed time from last start.
  def split
    Time.now - @start
  end

  # increase the event count
  def newEvent
    @events = @events + 1
  end

  # increase the events counts by multiple events
  def newEvents(num_events)
    @events = @events + num_events
  end

  # return the current summary in form: [elapsed, number events, start time, end time]
  def summary
    elapsed = 0
    if !@start.nil?
      end_time = !@end.nil? ? @end : Time.now
      elapsed = end_time - @start
    end
    @elapsed = @elapsed + elapsed
    [@elapsed, @events,@name]
  end

  def pretty_summary
    s = summary
    sprintf("%.3f,%d,%s",s[0],s[1],s[2])
  end

  # include some other stopwatch data.  This is useful when recording a sequence
  # but aren't sure when you start at the time it runs which stopwatch it should contribute to.
  # Allows you to keep a stopwatch for an event and then add that data to another, broader, summary one.
  def include(stopwatch)
    stopwatch.stop
  end
end
