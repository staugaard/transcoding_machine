require 'right_aws'
require 'transcoding_machine/server/s3_storage'

module TranscodingMachine
  module Server
    class JobQueue
      def initialize
        @sqs = RightAws::SqsGen2.new
        @s3 = RightAws::S3.new(nil, nil, :server => 's3.amazonaws.com', :port => 80, :protocol => 'http')
        Transcoder.options[:storage] = S3Storage.new
      end

      def start_consuming(in_queue_names, media_players, media_formats)
        @in_queue_names = in_queue_names.compact.uniq
        @media_players = media_players
        @media_formats = media_formats

        @in_queues = @in_queue_names.map {|name| @sqs.queue(name) }
        @total_consumed_messages = 0
        @consumption_started_at = Time.now
        @last_active_at = Time.now
        @active = false

        number_of_consumed_messages = [1]

        while(number_of_consumed_messages.any? {|n| n > 0})
          number_of_consumed_messages = @in_queues.map do |queue|
            consume_queue(queue)
          end
        end
      end

      def consume_queue(queue)
        puts "consuming queue #{queue.name}"
        number_of_consumed_messages = 0

        while message = queue.pop
          consume_message(message)
          number_of_consumed_messages += 1
          sleep(10)
        end
        sleep(10) if number_of_consumed_messages == 0
        number_of_consumed_messages
      end

      def consume_message(message)
        @active = true
        message_properties = YAML.load(message.body)
        puts "consuming message #{message_properties.inspect}"
        selected_media_players = find_media_players(message_properties[:media_players])
        if selected_media_players.any?
          if bucket = @s3.bucket(message_properties[:bucket].to_s)
            key = bucket.key(message_properties[:key].to_s)
            if key.exists?
              transcoder = Transcoder.new(key.name, selected_media_players, @media_formats, MessageEventListener.new(message_properties), :bucket => bucket.name)
              transcoder.start
            else
              puts "key not found"
            end
          else
            puts "bucket not found"
          end
        else
          puts "no media players found"
        end
        @active = false
        @last_active_at = Time.now
      end

      def find_media_players(media_player_ids)
        @media_players.slice(*media_player_ids).values
      end
    end

    class MessageEventListener
      def initialize(message_properties)
        @message_properties = message_properties
        @result_queue = RightAws::SqsGen2.new.queue(message_properties[:result_queue])
      end

      def getting_source_file
        push_status(:downloading)
      end

      def got_source_file

      end

      def analyzing_source_file
        push_status(:analyzing)
      end

      def analyzed_source_file(source_file_attributes, source_media_format)
        push_status(:analyzed, :media_format => source_media_format, :media_attributes => source_file_attributes)
      end

      def generating_thumbnail_file
        push_status(:creating_thumbnail)
      end

      def generated_thumbnail_file

      end

      def transcoding(media_format)
        push_status(:transcoding, :media_format => media_format)
      end

      def transcoded(media_format)
        push_status(:transcoded, :media_format => media_format)
      end

      def putting_destination_file(file_path, media_format)
        push_status(:uploading, :media_format => media_format, :destination_key => file_path)
      end

      def put_destination_file(file_path, media_format)
        push_status(:uploaded, :media_format => media_format, :destination_key => file_path)
      end


      def push_status(status, options = {})
        msg = @message_properties.clone
        msg[:status] = status
        msg.merge!(options)
        @result_queue.push(msg.to_yaml)
      end
    end
  end
end

require 'transcoding_machine'
require 'transcoding_machine/server/job_queue'

media_players, media_formats = TranscodingMachine.load_models_from_json(File.read('../test/fixtures/serialized_models.json'))

q = TranscodingMachine::Server::JobQueue.new
q.start_consuming(['tm-test-in'], media_players, media_formats)
