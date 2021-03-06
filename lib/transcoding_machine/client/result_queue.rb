require 'right_aws'

module TranscodingMachine
  class ResultQueue
    def initialize(logger = nil)
      @sqs = RightAws::SqsGen2.new
      @consuming = false
      @logger = logger
    end

    def start_consuming(queue_names, &block)
      @queue_names = queue_names.compact.uniq
      @queues = @queue_names.map {|name| @sqs.queue(name) }
      @consuming = true
      
      while(@consuming)
        @queues.map do |queue|
          consume_queue(queue, &block)
        end
      end
    end
    
    def consume_queue(queue, &block)
      puts "consuming queue #{queue.name}"
      number_of_consumed_messages = 0
      
      while message = queue.pop
        consume_message(message, &block)
        number_of_consumed_messages += 1
      end
      sleep(5) if number_of_consumed_messages == 0
      number_of_consumed_messages
    end
    
    def consume_message(message, &block)
      message_properties = YAML.load(message.body)
      
      begin
        yield(message_properties)
      rescue Exception => e
        @logger.error(e) if @logger
      end
      
      @last_active_at = Time.now
    end
  end
end
