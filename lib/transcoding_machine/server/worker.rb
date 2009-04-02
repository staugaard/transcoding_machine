require File.expand_path('../server', File.dirname(__FILE__))
require 'right_aws'
require 'transcoding_machine/server/ec2_environment'
require 'transcoding_machine/server/transcoding_event_listener'

if ARGV.size >= 1
  log = File.new(ARGV[0], "a")
end
log = log || STDERR

module TranscodingMachine
  module Server
    class Worker
      # initialize queues from names
      def initialize(log)
        @log = log
        @shutdown = false
        @state = "none"
        @last_status_time = Time.now
        @sqs = RightAws::SqsGen2.new
        @s3 = RightAws::S3.new(nil, nil, :server => 's3.amazonaws.com', :port => 80, :protocol => 'http')

        begin
          @work_queue = @sqs.queue(Ec2Environment.work_queue_name)
          if @work_queue.nil?
            @log.puts "error #{$!} #{Ec2Environment.work_queue_name}"
            raise "no work queue"
          end
          @status_queue = @sqs.queue(Ec2Environment.status_queue_name)
          if @status_queue.nil?
            @log.puts "error #{$!} #{Ec2Environment.status_queue_name}"
            raise "no status queue"
          end
        rescue
          @log.puts "error #{$!}"
          raise "cannot list queues"
        end

        @media_players, @media_formats = TranscodingMachine.load_models_from_hash(Ec2Environment.transcoding_settings)
        Transcoder.options[:storage] = S3Storage.new

        set_state("idle")
      end

      def send_status_message(status)
        now = Time.now
        msg = { :type => 'status',
          :instance_id => Ec2Environment.instance_id,
          :state => 'active',
          :load_estimate => status == 'busy' ? 1 : 0,
          :timestamp => now}
        @status_queue.push(msg.to_yaml)
        @last_status_time = now
      end

      def send_log_message(message)
        @log.puts message
        msg = { :type => 'log',
          :instance_id => Ec2Environment.instance_id,
          :message => message,
          :timestamp => Time.now}
        @status_queue.push(msg.to_yaml)
      end

      # Send status when state changes, when state becomes busy, or
      # every minute (even if there is no state change).
      def set_state(new_state)
        if new_state != @state ||
            new_state == "busy" ||
            @last_status_time + 60 < Time.now
          @state = new_state
          send_status_message(new_state)
        end
      end

      def handle_message(msg)
        #pp msg
        set_state("busy")

        start_time = Time.now

        send_log_message "Transcoding: BLA BLA BLA"

        message_properties = YAML.load(msg.body)
        puts "consuming message #{message_properties.inspect}"
        selected_media_players = find_media_players(message_properties[:media_players])
        if selected_media_players.any?
          if bucket = @s3.bucket(message_properties[:bucket].to_s)
            key = bucket.key(message_properties[:key].to_s)
            if key.exists?
              transcoder = Transcoder.new(key.name,
                                          selected_media_players,
                                          @media_formats,
                                          TranscodingEventListener.new(message_properties),
                                          :bucket => bucket.name)
              transcoder.start
            else
              send_log_message "Input file not found (bucket: #{message_properties[:bucket]} key: #{message_properties[:key]})"
            end
          else
            send_log_message "Input bucket not found (bucket: #{message_properties[:bucket]})"
          end
        else
          send_log_message "No media players found #{message_properties[:media_players].inspect}"
        end

        end_time = Time.now

        if true #test if transcode was successful
          msg.delete
          send_log_message "Transcoded: BLA BLA BLA"
        end
      end

      def find_media_players(media_player_ids)
        @media_players.slice(*media_player_ids).values
      end

      def message_loop
        msg = @work_queue.pop
        if msg.nil?
          #@log.puts "no messages"
          set_state("idle")
          sleep 5
        else
           handle_message(msg)
        end
      end

      def shutdown
        @shutdown = true
      end

      def run
        while ! @shutdown
          message_loop
        end
      end

    end
  end
end

begin
  TranscodingMachine::Server::Ec2Environment.logger = log
  TranscodingMachine::Server::Ec2Environment.load
  
  transcoding_machine = TranscodingMachine::Server::Worker.new(log)

  # Catch interrupts
  Signal.trap("INT") do
    transcoding_machine.shutdown
  end

  # Run the prime generator.
  transcoding_machine.run
rescue
  log.puts "error #{$!}"
  pp "#{$@}"
  exit 1
end
