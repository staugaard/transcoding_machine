require 'rubygems'
require 'activesupport'
require 'transcoding_machine/media_format'
require 'transcoding_machine/media_format_criterium'
require 'transcoding_machine/media_player'
require 'transcoding_machine/media_file_attributes'
require 'transcoding_machine/transcoder'

module TranscodingMachine
  module_function
  def load_models_from_json(json_string)
    load_models_from_hash(ActiveSupport::JSON.decode(json_string))
  end
  
  def load_models_from_hash(models_hash)
    media_formats = Hash.new
    models_hash['media_formats'].each do |id, attributes|
      attributes[:id] = id
      attributes.symbolize_keys!
      if attributes[:criteria]
        attributes[:criteria].map! {|c| MediaFormatCriterium.new(:key => c['key'],
                                                                 :operator => c['operator'],
                                                                 :value => c['value'])}
      end
      case attributes[:type]
      when 'video'
        media_formats[id] = VideoFormat.new(attributes)
      when 'audio'
        media_formats[id] = AudioFormat.new(attributes)
      end
    end
    
    media_players = Hash.new
    models_hash['media_players'].each do |id, attributes|
      attributes[:id] = id
      attributes.symbolize_keys!
      attributes[:formats].map! {|format_id| media_formats[format_id] }
      media_players[id] = MediaPlayer.new(attributes)
    end
    
    [media_players, media_formats.values.sort {|f1, f2| f2.priority <=> f1.priority}]
  end
end
