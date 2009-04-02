require 'right_aws'

module TranscodingMachine
  module Server
    class S3Storage
      def initialize
        @s3 = RightAws::S3.new(nil, nil, :server => 's3.amazonaws.com', :port => 80, :protocol => 'http')
      end

      def get_file(key_name, destination_file_path, options)
        file = File.new(destination_file_path, File::CREAT|File::RDWR)
        rhdr = @s3.interface.get(options[:bucket], key_name) do |chunk|
          file.write(chunk)
        end
        file.close
      end

      def put_file(source_file_path, destination_file_name, media_format, options)
        destination_key = RightAws::S3::Key.create(@s3.bucket(options[:bucket]), destination_file_name)
        s3_headers = { 'Content-Type' => media_format.mime_type,
                       'Content-Disposition' => "attachment; filename=#{File.basename(destination_file_name)}"
                     }

        destination_key.put(File.new(source_file_path), 'public-read', s3_headers)
        FileUtils.rm(source_file_path)
      end

      def put_thumbnail_file(thumbnail_file, source_file_key_name, options)
        destination_key = RightAws::S3::Key.create(@s3.bucket(options[:bucket]), "#{source_file_key_name}.thumb.jpg")
        destination_key.put(thumbnail_file, 'public-read', 'Content-Type' => 'image/jpg')
        FileUtils.rm(thumbnail_file.path)
      end
    end
  end
end