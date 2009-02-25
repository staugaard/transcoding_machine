module TranscodingMachine
  class Queue
    def initialize(in_queue_names, transcoder, media_players, aws_settings = {})
      @in_queue_names = in_queue_names.compact.uniq
      @transcoder = transcoder
      @media_players = media_players

      @sqs = RightAws::SqsGen2.new(nil, nil, aws_settings)
      @s3 = RightAws::S3.new(nil, nil, aws_settings)
      @in_queues = @in_queue_names.map {|name| sqs.queue(name) }
      @total_consumed_messages = 0
      @consumption_started_at = Time.mow
    end
    
    def start_consuming
      @consumption_started_at = Time.mow
      
      number_of_consumed_messages = [1]
      
      while(number_of_consumed_messages.any? {|n| n > 0})
        number_of_consumed_messages = @in_queues.map do |queue|
          consume_queue(queue)
        end
      end
    end
    
    def consume_queue(queue)
      number_of_consumed_messages = 0
      
      while message = queue.pop
        consume_message(message)
        number_of_consumed_messages += 1
        sleep(30)
      end
      sleep(30) if number_of_consumed_messages == 0
      number_of_consumed_messages
    end
    
    def consume_message(message)
      message_properties = YAML.load(message.body)
      selected_media_players = find_media_players(message_properties[:media_players])
      
      if selected_media_players.any?
        if bucket = @s3.bucket(message_properties[:bucket_name])
          key = bucket.key(message_properties[:key])
          if key.exists?
            transcoder = Transcoder.new(key.name, selected_media_players, MessageEventListener.new(message_properties), :bucket => bucket.name)
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
      
    end
    
    def find_media_players(media_player_ids)
      @media_players.slice(*message_properties[:media_players])
    end
  end
  
  class MessageEventListener
    def initialize(message_properties)
      @message_properties = message_properties
    end
    
    def getting_source_file
      
    end
    
    def got_source_file
      
    end
    
    def analyzing_source_file
      
    end
    
    def analyzed_source_file
      
    end
    
    def generating_thumbnail_file
      
    end
    
    def generated_thumbnail_file
      
    end
    
    def transcoding(media_format)
      
    end
    
    def transcoded(media_format)
      
    end
    
    def putting_destination_file(file_path, media_format)
      
    end
    
    def put_destination_file(file_path, media_format)
      
    end
  end
end