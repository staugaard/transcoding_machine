require 'transcoding_machine/media_file_attributes'
require 'transcoding_machine/file_storage'

module TranscodingMachine
  class Transcoder
    @@options = {:work_directory => '/tmp', :storage => TranscodingMachine::FileStorage.new}
    def self.options
      @@options
    end
    
    def work_directory
      self.class.options[:work_directory]
    end

    def storage
      self.class.options[:storage]
    end

    def initialize(source_file_name, media_players, event_handler = nil, storage_options = {})
      @source_file_name = source_file_name
      @event_handler = event_handler
      @media_players = media_players
      @storage_options = storage_options
    end

    def source_file_path
      @source_file_path ||= File.expand_path(@source_file_name, work_directory)
    end

    def source_file_directory
      @source_file_directory ||= File.dirname(source_file_path)
    end

    def destination_file_name(media_format)
      @source_file_name + media_format.suffix
    end

    def destination_file_path(media_format)
      File.expand_path(destination_file_name(media_format), work_directory)
    end

    def start
      prepare_working_directory
      get_source_file
      source_file_attributes = analyze_source_file

      thumbnail_file_path = generate_thumbnail(source_file_attributes)
      storage.put_thumbnail_file(thumbnail_file_path, @source_file_name, @storage_options) if thumbnail_file_path

      media_formats = @media_players.map {|mp| mp.best_format_for(source_file_attributes)}.compact.uniq
      media_formats.each do |media_format|
        destination_file_path = transcode(source_file_attributes, media_format)
        put_destination_file(destination_file_path, media_format)
      end
      clear
    end

    def prepare_working_directory
      if !File.exist?(source_file_directory)
        puts "creating directory #{source_file_directory}"
        FileUtils.mkdir_p(source_file_directory)
      end
    end

    def get_source_file
      @event_handler.getting_source_file if @event_handler
      storage.get_file(@source_file_name, source_file_path, @storage_options)
      @event_handler.got_source_file if @event_handler
    end

    def analyze_source_file
      @event_handler.analyzing_source_file if @event_handler

      source_file_attributes = MediaFileAttributes.new(source_file_path)

      @event_handler.analyzed_source_file if @event_handler
      source_file_attributes
    end
    
    def generate_thumbnail(source_file_attributes)
      if source_file_attributes.video?
        @event_handler.generating_thumbnail_file if @event_handler
        file = source_file_attributes.thumbnail_file
        @event_handler.generated_thumbnail_file if @event_handler
        file
      else
        nil
      end
    end

    def transcode(source_file_attributes, media_format)
      @event_handler.transcoding(media_format) if @event_handler

      dst_file_path = destination_file_path(media_format)
      cmd = command_for(source_file_attributes, media_format, dst_file_path)
      commands = cmd.split(' && ')
      puts "Number of commands to run: #{commands.size}"

      commands.each do |command|
        puts "Running command: #{command}"
        result = begin
          timeout(1000 * 60 * 55) do
            puts IO.popen(command).read
          end
        rescue Timeout::Error => e
          puts "TIMEOUT REACHED WHEN RUNNING COMMAND"
        end
      end

      @event_handler.transcoded(media_format) if @event_handler
      dst_file_path
    end

    def put_destination_file(file_path, media_format)
      @event_handler.putting_destination_file(file_path, media_format) if @event_handler
      storage.put_file(destination_file_path(media_format), destination_file_name(media_format), media_format, @storage_options)
      @event_handler.put_destination_file(file_path, media_format) if @event_handler
    end
    
    def clear
      FileUtils.rm(source_file_path)
    end

    def command_for(source_file_attributes, media_format, destination_file_path)
      command_variables = {
        'in_file_name' => "\"#{source_file_path}\"",
        'in_directory' => "#{source_file_directory}",
        'out_file_name' => "\"#{destination_file_path}\"",
        'out_directory' => "#{source_file_directory}"
      }
      
      command_variables['fps'] = target_fps(source_file_attributes) if source_file_attributes.video_fps
      
      cmd = media_format.command.strip
      
      command_variables.each {|key, value| cmd.gsub!("{{#{key}}}", value.to_s) }
      
      cmd
    end
    
    def target_fps(source_file_attributes)
      if fps = source_file_attributes.video_fps
        fps > 30 ? 25 : fps
      else
        nil
      end
    end
  end 
end
