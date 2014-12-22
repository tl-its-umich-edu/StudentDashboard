class Stopwatch

  # Add methods to stop / start timing.

  def initialize
    reset
  end

  # null out the stopwatch data
  def reset()
    # starting and end times for the current interval
    # end of current interval
    @end = nil
    # start of currently running interval or nil if there isn't one.
    @start = nil
    # elapsed time outside of the current interval.  E.g. might pause and restart.
    @elapsed = 0
    # number of events in the full elapsed interval.
    @events = 0
  end

# Start timing
  def start()
    reset
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
      end_time = !@end.nil? ? @end : Time.now - @start
      elapsed = end_time - @start
    end
    @elapsed = @elapsed + elapsed
    [@elapsed, @events]
  end

  # include some other stopwatch data.  This is useful when recording a sequence
  # but aren't sure when you start at the time it runs which stopwatch it should contribute to.
  # Allows you to keep a stopwatch for an event and then add that data to another, broader, summary one.
  def include(stopwatch)
    stopwatch.stop
  end
end
