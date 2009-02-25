module TranscodingMachine
  class S3Storage
    def initialize(aws_settings = {})
      @s3 = RightAws::S3.new(nil, nil, aws_settings)
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

    def put_thumbnail_file(thumbnail_file_path, source_file_key_name, options)
      destination_key = RightAws::S3::Key.create(@s3.bucket(options[:bucket]), "#{source_file_key_name}.thumb.jpg")
      destination_key.put(File.new(thumbnail_file_path), 'public-read', 'Content-Type' => 'image/jpg')
      FileUtils.rm(thumbnail_file_path)
    end
  end
end