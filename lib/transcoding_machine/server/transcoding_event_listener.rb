require 'right_aws'

module TranscodingMachine
  module Server
    class TranscodingEventListener
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
        push_status(:analyzed, :media_format => source_media_format.id, :media_attributes => source_file_attributes)
      end

      def generating_thumbnail_file
        push_status(:creating_thumbnail)
      end

      def generated_thumbnail_file
        push_status(:created_thumbnail)
      end

      def transcoding(media_format)
        push_status(:transcoding, :media_format => media_format.id)
      end

      def transcoded(media_format)
        push_status(:transcoded, :media_format => media_format.id)
      end

      def putting_destination_file(file_path, media_format)
        push_status(:uploading, :media_format => media_format.id, :destination_key => file_path)
      end

      def put_destination_file(file_path, media_format)
        push_status(:uploaded, :media_format => media_format.id, :destination_key => file_path)
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
