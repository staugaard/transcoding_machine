require File.dirname(__FILE__) + '/test_helper'

class MediaFormatCriteriumTest < Test::Unit::TestCase
  def test_equals_operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :file_name,
                                                             :operator => :equals,
                                                             :value => 'file_name')
    assert(criterium.matches(:file_name => 'file_name'))
    assert(!criterium.matches(:file_name => 'bad_file_name'))
  end
  
  def test_not_equals_operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :file_name,
                                                             :operator => :not_equals,
                                                             :value => 'bad_file_name')
    assert(criterium.matches(:file_name => 'file_name'))
    assert(!criterium.matches(:file_name => 'bad_file_name'))
  end
  
  def test_less_than_operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :bitrate,
                                                             :operator => :lt,
                                                             :value => 1000)
    assert(criterium.matches(:bitrate => 500))
    assert(!criterium.matches(:bitrate => 1000))
    assert(!criterium.matches(:bitrate => 2000))
  end
  
  def test_less_than_or_equals operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :bitrate,
                                                             :operator => :lte,
                                                             :value => 1000)
    assert(criterium.matches(:bitrate => 500))
    assert(criterium.matches(:bitrate => 1000))
    assert(!criterium.matches(:bitrate => 2000))
  end
  
  def test_greater_than_operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :bitrate,
                                                             :operator => :gt,
                                                             :value => 1000)
    assert(!criterium.matches(:bitrate => 500))
    assert(!criterium.matches(:bitrate => 1000))
    assert(criterium.matches(:bitrate => 2000))
  end
  
  def test_greater_than_or_equals operator
    criterium = TranscodingMachine::MediaFormatCriterium.new(:key => :bitrate,
                                                             :operator => :gte,
                                                             :value => 1000)
    assert(!criterium.matches(:bitrate => 500))
    assert(criterium.matches(:bitrate => 1000))
    assert(criterium.matches(:bitrate => 2000))
  end
end
