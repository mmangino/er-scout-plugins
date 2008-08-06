require 'timeout'
class MissingLibrary < StandardError; end
class TestFailed < StandardError; end 
class MemcachedMonitor < Scout::Plugin

  
  attr_accessor :connection
  
  
  def setup_memcache
    begin
      require 'memcache'
    rescue LoadError
      begin
        require "rubygems"
        require 'memcache'
      rescue LoadError
        raise MissingLibrary
      end
    end
    self.connection=MemCache.new("#{option(:host)}:#{option(:port)}")
  end
  
    
  
  def build_report
    begin
      setup_memcache
      test_setting_value
      test_getting_value
      report(option(:host)=>"OK")
    rescue Timeout::Error => e
      alert("Memcached failed to respond","Memcached on #{option(:host)} failed to respond within #{timeout_value} seconds")
    rescue MemCache::MemCacheError => e
      alert("Memcache connection failed","unable to connect to memcache on #{option(:host)}")
    rescue TestFailed=>e
      #do nothing, we already alerted, so no report  
    rescue MissingLibrary=>e
      error("Could not load all required libraries",
            "I failed to load the starling library. Please make sure it is installed.")
    rescue Exception=>e
      error("Got unexpected error: #{e} #{e.class}")
    end
  end
  
  def test_setting_value
    @test_value=rand.to_s
    timeout(timeout_value) do
      connection.set(option(:key),@test_value)
    end
  end
  
  def timeout_value
    (option(:timeout)||1).to_f
  end

  def test_getting_value
    value=""
    timeout(timeout_value) do
      value=connection.get(option(:key))
    end
    if value != @test_value
      alert("Unable to retrieve key from #{option(:host)}","Expected #{@test_value} but got #{value}")
      raise TestFailed
    end
  end

end