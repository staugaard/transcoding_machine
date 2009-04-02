require 'transcoding_machine/media_format'
require 'transcoding_machine/server/media_file_attributes'

module TranscodingMachine
  class MediaFormatCriterium
    TYPE_OPERATORS = {
      :boolean => [:equals, :not_equals],
      :string  => [:equals, :not_equals],
      :integer => [:equals, :not_equals, :lt, :lte, :gt, :gte],
      :float   => [:equals, :not_equals, :lt, :lte, :gt, :gte],
      :codec   => [:equals, :not_equals]
    }

    attr_reader :key, :operator, :value
    def initialize(args)
      @key = args[:key].to_sym
      
      @operator = (args[:operator] || :equals).to_sym
      
      @value = MediaFormat.type_cast_attribute_value(@key, args[:value])
      
      unless MediaFormatCriterium::TYPE_OPERATORS[value_type].include?(@operator)
        raise "invalid operator (#{@operator}) for MediaFormatCriterium with key #{@key}"
      end
    end
    
    def value_type
      Server::MediaFileAttributes::FIELD_TYPES[@key]
    end
    
    def matches(media_file_attributes)
      attr_value = MediaFormat.type_cast_attribute_value(@key, media_file_attributes[@key])
      case @operator
      when :equals
        attr_value == @value
      when :lt
        attr_value < @value
      when :gt
        attr_value > @value
      when :lte
        attr_value <= @value
      when :gte
        attr_value >= @value
      when :not_equals
        attr_value != @value
      end
    end
    
  end
end
