class MissingLibrary < StandardError; end
class StarlingMonitor < Scout::Plugin

  
  attr_accessor :connection
  
  
  def setup_starling
    begin
      require 'starling'
    rescue LoadError
      begin
        require "rubygems"
        require 'starling'
      rescue LoadError
        raise MissingLibrary
      end
    end
    self.connection=Starling.new("#{option(:host)}:#{option(:port)}")
  end
  
  def build_report
    begin
      setup_starling
      connection.sizeof(:all).each do |queue_name,item_count|
        check_queue(queue_name,item_count) if should_check_queue?(queue_name)
      end
    rescue  MissingLibrary=>e
      error("Could not load all required libraries",
            "I failed to load the starling library. Please make sure it is installed.")
    rescue Exception=>e
      error("Got unexpected error: #{e} #{e.class}")
    end
  end

  def should_check_queue?(name)
    option(:queue_re).nil? or /#{option(:queue_re)}/ =~ name
  end
  
  def check_queue(name,depth)
    q_depth = (depth||0).to_i
    report(name => q_depth)
    if q_depth > option(:max_depth).to_i
      alert("Max Queue Depth for #{name} exceeded","#{q_depth} items is more than the max allowed #{option(:max_depth)}")
    end
  end

end