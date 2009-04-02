require 'right_aws'
require 'transcoding_machine/server/s3_storage'

module TranscodingMachine
  module Client
    class JobQueue
      def initialize
        @sqs = RightAws::SqsGen2.new
      end

      def push(queue_name, bucket, key, media_player_ids, result_queue_name)
        msg = {:bucket => bucket, :key => key, :media_players => media_player_ids, :result_queue => result_queue_name}
        @sqs.queue(queue_name).push(msg.to_yaml)
      end
    end
  end
end
