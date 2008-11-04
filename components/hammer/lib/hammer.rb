class Hammer
  
  def initialize(adhearsion)  
    @adhearsion = adhearsion
    #Load the configuration file
    config_file = File.expand_path(File.dirname(__FILE__) + "/../config/application.yml")
    @config = YAML::load_file(config_file)
    @thread_lock = Mutex.new
    build_strategies
  end
  
  def make_calls
    cnt = 0
    while cnt < @config["cycle_length"] do
      if @config["thread_cycles"] == true
        Thread.new do
          execute_strategies
        end
      else
        execute_strategies
      end
      cnt += 1
    end
    return @config["delay_between_cycles"]
  end
  
  private
  
  #Build our strategies from the configuration file
  def build_strategies
    @dial_strategies = Array.new
    @config["dial_strategies"].each do |strategy|
      instructions = "send_dtmf=" + strategy["send_dtmf"].to_s
      instructions = instructions + "|before_delay=" + strategy["before_delay"].to_s
      instructions = instructions + "|after_delay=" + strategy["after_delay"].to_s
      instructions = instructions + "|message=" + strategy["message"]

      if strategy["call_length"] == 'random'
        instructions = instructions + "|call_length=" + rand(@config["max_random_call_length"]).to_s
      else
        instructions = instructions + "|call_length=" + strategy["call_length"].to_s
      end

      @dial_strategies << { :instructions => instructions,
                            :callerid => strategy["callerid"],
                            :number => strategy["number"],
                            :profile => strategy["profile"].to_i - 1 }
    end
  end
  
  #Launch the individual phone calls
  def launch_call(dial_strategy)
    #Determine if the channel type is IAX2 or SIP and make a determination on how to dial
    channel_type = @config["profiles"][dial_strategy[:profile]]["channel"].split('/')
    if channel_type[0] == "IAX2"
      channel = @config["channel"] + dial_strategy[:number].to_s
    else
      channel = $HELPERS["hammer"][profile]["channel"] + dial_strategy[:number].to_s
    end
    
    @thread_lock.synchronize do
      response = @adhearsion.proxy.originate( { "Channel" => channel,
                                                "Context" =>  @config["profiles"][dial_strategy[:profile]]["context"],
                                                "Exten" =>  @config["profiles"][dial_strategy[:profile]]["extension"],
                                                "Priority" => @config["profiles"][dial_strategy[:profile]]["priority"],
                                                "Callerid" => dial_strategy[:callerid],
                                                "Timeout" => @config["profiles"][dial_strategy[:profile]]["timeout"],
                                                "Variable" => dial_strategy[:instructions],
					                                      "Async" => @config["profiles"][dial_strategy[:profile]]["async"] } )
    end
					                                    
    return response
  end
  
  def execute_strategies
    @dial_strategies.each do |strategy|
      launch_call(dial_strategy)
      if @config["strategy"][dial_strategy[:profile]]["delay_between_calls"] == 'random'
        sleep rand(@config["strategy"][dial_strategy[:profile]]["max_random_between_calls"])
      else
        sleep @config["strategy"][dial_strategy[:profile]]["delay_between_calls"]
      end
    end
  end
  
end