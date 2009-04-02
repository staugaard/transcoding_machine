require 'right_aws'

module TranscodingMachine
  module Client
    class ServerManager
      
      # Sets up a new ServerManager
      # queue_settings are a in the following format:
      # {'transcoding_job_queue' => {:ami => 'ami-e444444d',
      #                              :location => 'us-east-1c',
      #                              :key => 'my_awesome_key',
      #                              :type => 'm1.large'}
      # }
      # 
      # options are:
      # * <tt>:sleep_time</tt> the time to sleep between queue checks (default 30)
      # * <tt>:transcoding_settings</tt> a string or lambda with the userdata to send to new transcoding servers
      # * <tt>:server_count</tt> a lambda returning the needed number of transcoding servers for a given queue (defaults to the queue size)
      def initialize(queue_settings, options)
        @sqs = RightAws::SqsGen2.new
        @ec2 = RightAws::Ec2.new
        
        @queues = Hash.new
        queue_settings.each do |queue_name, settings|
          @queues[@sqs.queue(queue_name.to_s)] = settings
        end
        
        @server_count = options[:server_count] || lambda {|queue| queue.size}
        
        @transcoding_settings = options[:transcoding_settings]
        
        @sleep_time = options[:sleep_time] || 20
        
        @running = false
      end
      
      def needed_server_count(queue)
        @server_count.call(queue)
      end
      
      def transcoding_settings(queue)
        "test"
        #@transcoding_settings.respond_to?(:call) ? @transcoding_settings.call(queue) : @transcoding_settings
      end
      
      def running_server_count(queue)
        @ec2.describe_instances.find_all do |instance|
          state = instance[:aws_state_code].to_i
          zone = instance[:aws_availability_zone]
          ami = instance[:aws_image_id]
          
          matches = state <= 16
          matches &&= ami == ec2_ami(queue)
          matches &&= zone == ec2_location(queue) if ec2_location(queue)
          matches
        end.size
      end
      
      def ec2_ami(queue)
        @queues[queue][:ami]
      end

      def ec2_location(queue)
        @queues[queue][:location]
      end
      
      def ec2_key(queue)
        @queues[queue][:key]
      end

      def ec2_instance_type(queue)
        @queues[queue][:type]
      end
      
      def ec2_security_groups(queue)
        @queues[queue][:security_groups]
      end

      def manage_servers(options = {})
        @running = true
        
        while @running
          @queues.keys.each do |queue|
            needed = needed_server_count(queue)
            running = running_server_count(queue)
            
            #if needed > 0 || running > 0
              puts "#{running} of #{needed} needed servers are running for queue #{queue.name}"
            #end
            
            if running < needed
              puts "requesting #{needed - running} new servers for queue #{queue.name}"
              puts [ec2_ami(queue), 1, needed - running, ec2_security_groups(queue),
                                               ec2_key(queue), transcoding_settings(queue),
                                               nil, ec2_instance_type(queue), nil, nil, ec2_location(queue)].inspect
                                               
              new_servers = @ec2.run_instances(ec2_ami(queue), 1, needed - running, ec2_security_groups(queue),
                                               ec2_key(queue), transcoding_settings(queue),
                                               nil, ec2_instance_type(queue), nil, nil, ec2_location(queue))
            end
          end
          sleep(@sleep_time)
        end
      end
    end
  end
end