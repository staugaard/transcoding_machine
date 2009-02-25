require 'transcoding_machine/media_format'

module TranscodingMachine
  class MediaPlayer
    attr_reader :formats
    def initialize(args)
      if args[:formats]
        @formats = args[:formats].sort {|f1, f2| f2.priority <=> f1.priority}
      end
      @formats ||= []
    end
    
    def best_format_for(media_file_attributes)
      @formats.find {|f| f.can_transcode?(media_file_attributes)}
    end
  end
end