require 'selenium-webdriver'

## Run tests against designated Latte server with fixed set of names.
## This script will do a single sequential run of queries and provides some
## timing data.  Run instances of this to get parallel load.  See the script
## runMany.sh

## Adjustable values are:
## - list of users
## - latte server URL
## - number of times to repeat the set of queries.

## NOTE THAT THIS REQUIRES THE SELENIUM SERVER TO BE RUNNING!
# It can be started as follows.  Probably want to redirect output
# java -jar selenium-server-standalone-2.44.0.jar

@host = "http://localhost:8080"
@baseUrl = "#{@host}/StudentDashboard/?UNIQNAME="
@driver = nil

class PollLatte
  # run query against for specific user against specific Latte instance.
  def self.runTest(base, uniqname)
    url = "#{base}#{uniqname}"
        if @driver.nil?
      caps = Selenium::WebDriver::Remote::Capabilities.htmlunit(:javascript_enabled => true, :cssSelectorsEnabled => true, :takesScreenshot => true)
      @driver = Selenium::WebDriver.for(:remote, :url => "http://localhost:4444/wd/hub", :desired_capabilities => caps)
      ## Was using "wait.until" below but it didn't wait.  Setting this here does wait successfully.
      @driver.manage.timeouts.implicit_wait = 10 # seconds
    end

    error = ""
    begin
    start = Time.now
    # ask query
    @driver.get url
    @driver.find_element(:xpath, '//span[@id=\'done\']')
    rescue => exp
      puts "rescue: exp: "+exp.inspect
      error = exp
    end
    stop = Time.now
    ## save the data
    PollLatte.printData(start, stop, url,error)

    # close this driver
    @driver.close
    @driver = nil
  end

  def self.printData(start, stop, url,error)
    elapsed = stop - start
    puts start.strftime("%s")+"\t#{$$}\t#{url}\t"+elapsed.to_s+"\t"+error.inspect
  end
end


@useIds = @ids

## do the queries a bunch of times.
runStart = Time.now

puts runStart.strftime("%s")+"\t#{$$}\tstart\t"+runStart.to_s
2.times do |i|
    @useIds.shuffle.each do |uname|
    PollLatte.runTest(@baseUrl, uname)
  end
end
runEnd = Time.now
puts runEnd.strftime("%s")+"\t#{$$}\tend\telapsed:\t"+(runEnd-runStart).to_s

#end
