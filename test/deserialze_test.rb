require File.dirname(__FILE__) + '/test_helper'

class DeserializeTest < Test::Unit::TestCase
  def test_deserialization
    puts TranscodingMachine.load_models_from_json(File.read('test/fixtures/serialized_models.json')).inspect
  end
end
