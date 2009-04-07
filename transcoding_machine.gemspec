# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{transcoding_machine}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mick Staugaard"]
  s.date = %q{2009-04-07}
  s.description = %q{TODO}
  s.email = %q{mick@staugaard.com}
  s.executables = ["transcoding_machine", "transcoding_machine_ec2_server"]
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["NOTES.txt", "VERSION.yml", "bin/transcoding_machine", "bin/transcoding_machine_ec2_server", "lib/transcoding_machine", "lib/transcoding_machine/client", "lib/transcoding_machine/client/job_queue.rb", "lib/transcoding_machine/client/result_queue.rb", "lib/transcoding_machine/media_format.rb", "lib/transcoding_machine/media_format_criterium.rb", "lib/transcoding_machine/media_player.rb", "lib/transcoding_machine/server", "lib/transcoding_machine/server/ec2_environment.rb", "lib/transcoding_machine/server/file_storage.rb", "lib/transcoding_machine/server/media_file_attributes.rb", "lib/transcoding_machine/server/s3_storage.rb", "lib/transcoding_machine/server/transcoder.rb", "lib/transcoding_machine/server/transcoding_event_listener.rb", "lib/transcoding_machine/server/worker.rb", "lib/transcoding_machine/server.rb", "lib/transcoding_machine.rb", "test/deserialze_test.rb", "test/dummy_server_mananager.rb", "test/fixtures", "test/fixtures/serialized_models.json", "test/media_format_criterium_test.rb", "test/media_format_test.rb", "test/media_player_test.rb", "test/test_helper.rb", "README", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/staugaard/transcoding_machine}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.2.2"])
      s.add_runtime_dependency(%q<unicode>, [">= 0.1"])
      s.add_runtime_dependency(%q<right_aws>, [">= 1.9.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.2.2"])
      s.add_dependency(%q<unicode>, [">= 0.1"])
      s.add_dependency(%q<right_aws>, [">= 1.9.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.2.2"])
    s.add_dependency(%q<unicode>, [">= 0.1"])
    s.add_dependency(%q<right_aws>, [">= 1.9.0"])
  end
end
