require 'selenium-webdriver'

#@latteurl = "http://localhost:3000/"
#@latteurl = "http://google.com"
@host = "http://localhost:8080"
@baseUrl = "#{@host}/StudentDashboard/?UNIQNAME="
@driver = nil
#@wait = Selenium::WebDriver::Wait.new(:timeout => 5) # seconds
#?UNIQNAME=ststvii"
#http://localhost:8080/StudentDashboard/?UNIQNAME=ulaby
class PollLatte
  # run query against for specific user against specific Latte instance.
  def self.runTest(base,uniqname)
    url = "#{base}#{uniqname}"
    ## make sure there is a driver.
    if @driver.nil?
      @driver = Selenium::WebDriver.for :firefox
      #@driver = Selenium::WebDriver.for :chrome
      #@driver.setJavascriptEnabled(true)
    end

    start = Time.now
    # ask query
    @driver.get url
    # wait until there is a response
    wait = Selenium::WebDriver::Wait.new(:timeout => 5) # seconds
    wait.until { @driver.find_element(:xpath, "//span[@id='done']") }
    stop = Time.now

    ## save the data
    PollLatte.printData(start,stop,url)

    # close this driver
    @driver.close
    @driver = nil
  end

  def self.printData(start,stop,url)
    elapsed = stop - start
    #puts start.to_s+"\t#{$$}\t#{url}\t"+elapsed.to_s
    puts start.strftime("%s")+"\t#{$$}\t#{url}\t"+elapsed.to_s
    #puts "epoch: "+start.strftime("%s")
  end
end

@ids1 = ["kgrahl"]

@ids2 = ["kgrahl","ststvii"]

@ids = [
    "kgrahl",
    "lyle",
    "moulib",
    "gckeeney",
    "ulaby",
    "aballard",
    "ulaby",
    "nassarj",
    "hannoosh",
    "ststvii",
    "jorhill"
]


@useIds = @ids

@useIds.shuffle.each do |uname|
  PollLatte.runTest(@baseUrl,uname)
end
@useIds.shuffle.each do |uname|
  PollLatte.runTest(@baseUrl,uname)
end
@useIds.shuffle.each do |uname|
  PollLatte.runTest(@baseUrl,uname)
end

#end
