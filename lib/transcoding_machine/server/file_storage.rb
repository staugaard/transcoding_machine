module TranscodingMachine
  module Server
    class FileStorage
      def initialize(root_directory = '.')
        @root = root_directory
      end

      def get_file(source_file_name, destination_file_path, options)
        puts File.expand_path(source_file_name, @root)
        puts destination_file_path
        FileUtils.cp(File.expand_path(source_file_name, @root), destination_file_path)
      end

      def put_file(source_file_path, destination_file_name, media_format, options)
        FileUtils.mv(source_file_path, File.expand_path(destination_file_name, @root))
      end

      def put_thumbnail_file(thumbnail_file_path, source_file, options)
        FileUtils.mv(thumbnail_file_path.path, @root)
        thumbnail_file_path.path
      end
    end
  end
end