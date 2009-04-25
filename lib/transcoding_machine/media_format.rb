require 'transcoding_machine/media_player'
require 'transcoding_machine/server/media_file_attributes'

module TranscodingMachine
  class MediaFormat
    attr_reader :criteria, :priority, :id, :suffix, :mime_type, :command
    
    def initialize(args)
      @fixed_criteria = []
      @priority = args[:priority]
      @id = args[:id]
      @suffix = args[:suffix]
      @mime_type = args[:mime_type]
      @command = args[:command]
      @criteria = args[:criteria] || []
    end
    
    def matches(media_file_attributes)
      (@fixed_criteria + @criteria).all? { |c| c.matches(media_file_attributes) }
    end
    
    def can_transcode?(media_file_attributes)
      
    end
    
    def self.type_cast_attribute_value(key, value)
      case Server::MediaFileAttributes::FIELD_TYPES[key]
      when :boolean
        (value.to_s.downcase == 'true' || value.to_s == '1')
      when :string
        value.to_s
      when :integer
        value.to_i
      when :float
        value.to_f
      when :codec
        value.to_sym
      else
        raise "unknown key (#{key}) for MediaFormat attribute"
      end
    end
    
    def self.best_match_for(media_file_attributes, sorted_formats)
      sorted_formats.first {|f| f.can_transcode?(media_file_attributes)}
    end
  end
  
  class AudioFormat < MediaFormat
    attr_reader :bitrate
    def initialize(args)
      super
      @bitrate = args[:bitrate]
      
      @fixed_criteria << MediaFormatCriterium.new(:key => :video,
                                                  :operator => :not_equals,
                                                  :value => true)
      
      @fixed_criteria << MediaFormatCriterium.new(:key => :audio,
                                                  :operator => :equals,
                                                  :value => true)
    end
    
    def can_transcode?(media_file_attributes)
      !media_file_attributes.video? && media_file_attributes.audio? && media_file_attributes.bitrate >= @bitrate
    end
  end
  
  class VideoFormat < MediaFormat
    attr_reader :width, :height, :aspect_ratio
    def initialize(args)
      super
      @width = args[:width]
      @height = args[:height]
      
      case args[:aspect_ratio]
      when String
        @aspect_ratio = Server::MediaFileAttributes::ASPECT_RATIO_VALUES[args[:aspect_ratio]]
      when Float
        @aspect_ratio = args[:aspect_ratio]
      end
      
      @fixed_criteria << MediaFormatCriterium.new(:key => :video,
                                                  :operator => :equals,
                                                  :value => true)
      
      @fixed_criteria << MediaFormatCriterium.new(:key => :width,
                                                  :operator => :equals,
                                                  :value => @width)
      
      @fixed_criteria << MediaFormatCriterium.new(:key => :aspect_ratio,
                                                  :operator => :equals,
                                                  :value => @aspect_ratio)
    end

    def can_transcode?(media_file_attributes)
      media_file_attributes.video? && media_file_attributes.width >= @width && media_file_attributes.aspect_ratio == @aspect_ratio
    end
  end
end
