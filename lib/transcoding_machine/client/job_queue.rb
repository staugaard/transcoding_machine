require 'right_aws'
require 'transcoding_machine/server/s3_storage'

module TranscodingMachine
  module Client
    class JobQueue
      def self.push(queue_name, bucket, key, media_player_ids, result_queue_name, options = {})
        options[:bucket] = bucket
        options[:key] = key
        options[:media_players] = media_player_ids
        options[:result_queue] = result_queue_name
        options[:action] = :analyze
        RightAws::SqsGen2.new.queue(queue_name).push(options.to_yaml)
      end
    end
  end
end
