class PageLoadFailed < StandardError; end
class MissingLibrary < StandardError; end
class ContentMonitor < Scout::Plugin

  
  attr_accessor :agent
  
  def setup_agent
    begin
      require "mechanize"
    rescue LoadError
      begin
        require "rubygems"
        require "mechanize"
      rescue LoadError
        raise MissingLibrary
      end
    end
    @agent = WWW::Mechanize.new
  end
  
  def build_report
    begin
      setup_agent
      url = option(:url)
      content=option(:content)
      check_status(url,content)
      report(url=>"OK")
      remember(url=>true)
    rescue  MissingLibrary=>e
      error("Could not load all required libraries",
            "I failed to load the mechanize library. Please make sure it is installed.")
    rescue  PageLoadFailed=>e
      alert(:subject=>"#{url} check failed",:body=>"Expected to contain '#{content}' but contained '#{e.to_s}") if memory(url)
      remember(url=>false)
    end
  end

  def check_status(url_to_monitor,text)
      3.times do
       begin
        puts "Checking status of #{url_to_monitor}"
        main_page =agent.get(url_to_monitor)
        unless main_page.body.match(/#{text}/)
          raise PageLoadFailed,main_page.body
        end
        return true

        rescue  Errno::ECONNRESET,Errno::EPIPE
          sleep 2
        end
      end
    end
  
end