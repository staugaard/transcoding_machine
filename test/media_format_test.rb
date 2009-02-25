require File.dirname(__FILE__) + '/test_helper'

class MediaFormatTest < Test::Unit::TestCase
  def test_executes_criteria_matchers
    media_format = TranscodingMachine::MediaFormat.new({})
    media_format.criteria << TranscodingMachine::MediaFormatCriterium.new(:key => :file_name,
                                                                          :operator => :equals,
                                                                          :value => 'file_name')
    media_format.criteria << TranscodingMachine::MediaFormatCriterium.new(:key => :bitrate,
                                                                          :operator => :equals,
                                                                          :value => 1000)
    
    assert(media_format.matches(:file_name => "file_name", :bitrate => 1000))
    assert(media_format.matches(:file_name => "file_name", :bitrate => 1000, :other_attribute => 'value'))
    assert(!media_format.matches(:file_name => "file_name"))
    assert(!media_format.matches(:bitrate => 1000))
    assert(!media_format.matches(:file_name => "bad_file_name", :bitrate => 1000))
    assert(!media_format.matches(:file_name => "file_name", :bitrate => 2000))
  end
  
  def test_video_format_checks_for_video
    video_format = TranscodingMachine::VideoFormat.new(:width => 320, :height => 240, :aspect_ratio => (4.0/3.0))
    
    assert(!video_format.matches({:width => 1280, :aspect_ratio => ((4.0/3.0))}))
    assert(video_format.matches({:video => true, :width => 1280, :aspect_ratio => ((4.0/3.0))}))
  end

  def test_audio_format_checks_for_video
    audio_format = TranscodingMachine::AudioFormat.new(:bitrate => 1000)
    
    assert(audio_format.matches({:video => false, :audio => true, :bitrate => 1000}))
    assert(!audio_format.matches({:video => true, :audio => true, :bitrate => 1000}))
  end
  
  def test_audio_format_checks_for_audio
    audio_format = TranscodingMachine::AudioFormat.new(:bitrate => 1000)
    
    assert(audio_format.matches({:video => false, :audio => true, :bitrate => 1000}))
    assert(!audio_format.matches({:video => false, :audio => false, :bitrate => 1000}))
  end
  
end
