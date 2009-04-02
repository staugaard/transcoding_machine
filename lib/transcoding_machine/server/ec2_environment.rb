require 'open-uri'
require 'yaml'
require 'right_aws'

module TranscodingMachine
  module Server
    class Ec2Environment
      @@logger = STDOUT
      @@data = nil
      @@transcoding_settings = nil
      
      def self.logger=(new_logger)
        @@logger = new_logger
      end
      
      def self.logger
        @@logger || STDOUT
      end
      
      def self.load
        !data.nil?
      end
      
      # Load user data
      def self.data
        return @@data if @@data
        begin
          logger.puts "Getting EC2 instance ID"
          iid = open('http://169.254.169.254/latest/meta-data/instance-id').read(200)
          logger.puts "Getting EC2 user data"
          user_data = open('http://169.254.169.254/latest/user-data').read(2000)
          data = YAML.load(user_data)
          aws = { :aws_env => data[:aws_env],
                  :aws_access_key => data[:aws_access_key],
                  :aws_secret_key => data[:aws_secret_key]
                }
          
          ENV['AWS_ACCESS_KEY_ID'] = data[:aws_access_key]
          ENV['AWS_SECRET_ACCESS_KEY'] = data[:aws_secret_key]
        rescue
          # when running locally, use fake iid
          iid = "unknown"
          user_data = nil
          aws = {}        
        end
        @@data = {:aws => aws, :iid => iid, :user_data => data}
      end

      def self.keys
        [data[:aws][:aws_access_key], data[:aws][:aws_secret_key]]
      end
      
      def self.instance_id
        data[:iid]
      end
      
      def self.transcoding_settings
        return @@transcoding_settings if @@transcoding_settings
        
        bucket = data[:user_data][:transcoding_settings][:bucket]
        key    = data[:user_data][:transcoding_settings][:key]
        
        logger.puts "Getting transcoding settings from S3 #{bucket}/#{key}"
        
        s3 = RightAws::S3.new
        
        @@transcoding_settings ||= YAML.load(s3.bucket(bucket).key(key).data)
      end
      
      def self.work_queue_name
        data[:user_data][:work_queue_name]
      end
      
      def self.status_queue_name
        data[:user_data][:status_queue_name]
      end
    end
  end
end