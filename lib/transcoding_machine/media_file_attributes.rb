require 'open3'
require 'pathname'
require 'timeout'
require 'unicode'

module TranscodingMachine
  class MediaFileAttributes < Hash
    ASPECT_RATIO_2_35_BY_1 = 2.35
    ASPECT_RATIO_16_BY_9 = 16.0 / 9.0
    ASPECT_RATIO_4_BY_3 = 4.0 / 3.0
    ASPECT_RATIO_NAMES = {ASPECT_RATIO_2_35_BY_1 => '2.35/1', ASPECT_RATIO_16_BY_9 => '16/9', ASPECT_RATIO_4_BY_3 => '4/3'}
    ASPECT_RATIO_VALUES = ASPECT_RATIO_NAMES.invert

    CODECS = {'ffmp3' => :mp3, 'mp3' => :mp3, 'faad' => :aac, 'ffh264' => :h264, 'h264' => :h264, 'ffvp6f' => :flash_video}

    TRACK_FIELD_TYPES = {
      :codec => :codec,
      :width => :integer,
      :height => :integer,
      :format => :string,
      :aspect => :float,
      :id => :integer,
      :bitrate => :integer,
      :fps => :float,
      :file_name => :string,
      :length => :float,
      :demuxer => :string,
      :rate => :integer,
      :channels => :integer
    }

    FIELD_TYPES = {
      :audio => :boolean,
      :audio_format => :string,
      :audio_rate => :integer,
      :audio_bitrate => :integer,
      :audio_codec => :codec,
      :audio_channels => :integer,
      :video => :boolean,
      :video_format => :string,
      :video_codec => :codec,
      :width => :integer,
      :height => :integer,
      :aspect_ratio => :float,
      :video_fps => :float,
      :video_bitrate => :integer,
      :ipod_uuid => :boolean,
      :bitrate => :integer,
      :length => :float,
      :file_name => :string,
      :file_extension => :string,
      :demuxer => :string,
      :poster_time => :float
    }

    def initialize(media_file_path)
      super()
      ffmpeg = FfmpegIntegrator.new(media_file_path)
      mplayer = MplayerIntegrator.new(media_file_path)

      puts "FFMPEG:\n#{ffmpeg.tracks.inspect}"

      puts "MPLAYER:\n#{mplayer.tracks.inspect}"

      store(:ipod_uuid, false)

      merge!(get_video_info(get_video_track(ffmpeg.tracks), get_video_track(mplayer.tracks)))
      merge!(get_audio_info(get_audio_track(ffmpeg.tracks), get_audio_track(mplayer.tracks)))
      merge!(get_container_info(ffmpeg.tracks[:container], mplayer.tracks[:container]))

      derive_values

      if video?
        atomic_parsley = AtomicParsleyIntegrator.new(media_file_path)
        puts "ATOMIC_PARSLEY:\n#{atomic_parsley.tracks.inspect}"
        store(:ipod_uuid, atomic_parsley.tracks[:container][:ipod_uuid])

        exiftool = ExifToolIntegrator.new(media_file_path)
        puts "EXIFTOOL:"
        puts exiftool.inspect
        store(:poster_time, exiftool.poster_time)
        if exiftool.aspect_ratio and video_aspect != exiftool.aspect_ratio
          store(:height, (width / exiftool.aspect_ratio).to_i)
          store(:video_aspect, exiftool.aspect_ratio)
        elsif exiftool.width && exiftool.height
          store(:width, exiftool.width)
          store(:height, exiftool.height)
          derive_values
        end
        fix_dimensions
      end

      delete_if {|key, value| value.nil?}
    end

    def video?
      video
    end

    def audio?
      audio
    end

    def thumbnail_file
      return @thumbnail_file if @thumbnail_file
      
      return nil unless video? and height and width
      
      time = poster_time
      if time.nil? or time == 0 or time > 30
        time = length / 10.0
        time = 10 if time > 10
      end
      
      @thumbnail_file = FfmpegIntegrator.create_thumbnail(file_name, width, height, time)
    end

    def self.parse_values(values)
      values.values.each do |track_values|
        track_values.each do |key, value|
          case TRACK_FIELD_TYPES[key]
          when :integer
            track_values[key] = value.to_i
          when :float
            track_values[key] = value.to_f
          when :codec
            track_values[key] = CODECS[value] || value
          end
        end
      end

      values
    end
    
    private

    def get_video_track(tracks)
      get_track_by_type(tracks, :video)
    end

    def get_audio_track(tracks)
      get_track_by_type(tracks, :audio)
    end

    def get_track_by_type(tracks, type)
      return nil if tracks.nil?
      tracks.values.each do |track|
        return track if track[:type] == type
      end
      nil
    end

    def has_real_video_track?(ffmpeg_video_track, mplayer_video_track)
      return false if ffmpeg_video_track.nil? && mplayer_video_track.nil?

      unless ffmpeg_video_track.nil?
        return false if ffmpeg_video_track[:codec] == 'png'
        return false if ffmpeg_video_track[:width] == 1
        return false if ffmpeg_video_track[:height] == 1
        return false if ffmpeg_video_track[:fps] && ffmpeg_video_track[:fps] > 1000
      end

      unless mplayer_video_track.nil?
        return false if mplayer_video_track[:format] == 'jpeg'
        return false if mplayer_video_track[:fps] == 0
      end

      ffmpeg_video_track ||= {}
      mplayer_video_track ||= {}

      return false if (ffmpeg_video_track[:codec].nil? && mplayer_video_track[:codec].nil?)
      return false if (ffmpeg_video_track[:width].nil? && mplayer_video_track[:width].nil?)
      return false if (ffmpeg_video_track[:height].nil? && mplayer_video_track[:height].nil?)

      return true
    end

    def has_real_audio_track?(ffmpeg_audio_track, mplayer_audio_track)
      unless ffmpeg_audio_track.nil?
        return true if ffmpeg_audio_track[:codec]
        return true if ffmpeg_audio_track[:format]
      end
      unless mplayer_audio_track.nil?
        return true if mplayer_audio_track[:codec]
        return true if mplayer_audio_track[:format]
      end
      return false
    end

    def get_video_info(ffmpeg_track, mplayer_track)
      return {:video => false} unless has_real_video_track?(ffmpeg_track, mplayer_track)

      ffmpeg_track ||= {}
      mplayer_track ||= {}

      output = {:video => true}

      output[:video_format] = ffmpeg_track[:format] || mplayer_track[:format]
      output[:width] = ffmpeg_track[:width] || mplayer_track[:width]
      output[:height] = ffmpeg_track[:height] || mplayer_track[:height]
      output[:video_aspect] = ffmpeg_track[:aspect] || mplayer_track[:aspect]
      output[:video_fps] = ffmpeg_track[:fps] || mplayer_track[:fps]
      output[:video_bitrate] = ffmpeg_track[:bitrate] || mplayer_track[:bitrate]

      if ffmpeg_track[:codec].class == String && mplayer_track[:codec].class == Symbol
        output[:video_codec] = mplayer_track[:codec]
      else
        output[:video_codec] = ffmpeg_track[:codec] || mplayer_track[:codec]
      end

      output
    end

    def get_audio_info(ffmpeg_track, mplayer_track)
      return {:audio => false} unless has_real_audio_track?(ffmpeg_track, mplayer_track)

      ffmpeg_track ||= {}
      mplayer_track ||= {}

      output = {:audio => true}

      output[:audio_format] = ffmpeg_track[:format] || mplayer_track[:format]
      output[:audio_rate] = ffmpeg_track[:rate] || mplayer_track[:rate]
      output[:audio_bitrate] = ffmpeg_track[:bitrate] || mplayer_track[:bitrate]
      output[:audio_channels] = ffmpeg_track[:channels] || mplayer_track[:channels]

      if ffmpeg_track[:codec].class == String && mplayer_track[:codec].class == Symbol
        output[:audio_codec] = mplayer_track[:codec]
      else
        output[:audio_codec] = ffmpeg_track[:codec] || mplayer_track[:codec]
      end

      output
    end

    def get_container_info(ffmpeg_track, mplayer_track)
      output = Hash.new

      high_prio = ffmpeg_track || {}
      low_prio = mplayer_track || {}

      output[:bitrate] = high_prio[:bitrate] || low_prio[:bitrate]
      output[:length] = high_prio[:length] || low_prio[:length]
      output[:file_name] = high_prio[:file_name] || low_prio[:file_name]
      output[:demuxer] = high_prio[:demuxer] || low_prio[:demuxer]
      output
    end

    def video_aspect_ratio
      return nil unless video?

      ratio = width.to_f / height.to_f

      return nil if ratio.nan?

      diffs = ASPECT_RATIO_NAMES.keys.map {|ar| [(ar - ratio).abs, ar]}

      diffs.sort! {|x, y| x[0] <=> y[0]}

      diffs.first[1]
    end

    def derive_values
      store(:video_aspect, video_aspect_ratio) if (video? && has_key?(:width) && has_key?(:height))

      if file_name && (m = file_name.match(/.+\.(\w+)/))
        store(:file_extension, m[1])
      end
    end

    def fix_dimensions
      [:width, :height].each do |key|
        if has_key?(key) and (fetch(key) % 2 == 1)
          store(key, fetch(key) - 1)
        end
      end
    end

    # Intercept calls
    def method_missing(method_name, *args)
      if (FIELD_TYPES[method_name])
        self[method_name]
      else
        super
      end
    end
  end
  
  class FfmpegIntegrator
    attr_accessor :tracks
    BINARY = ["ffmpeg"]
    OPTIONS = ["-i"]
    TIMEOUT = 60

    def initialize(file_path)
      commandline = []
      commandline += BINARY
      commandline += OPTIONS
      commandline += [file_path]
      puts "trying to run: #{commandline.join(' ')}"
      result = begin
        timeout(TIMEOUT) do
          Open3.popen3(*commandline) do |i, o, e|
            [o.read, e.read]
          end
        end
      rescue Timeout::Error => e
        puts "Timeout reached when inspecting #{file_path} with ffmpeg"
        raise e
      end

      result = result.join("\n")

      ffmpeg_values = Hash.new

      start_index = result.index("Input #0, ")
      @tracks = {}

      unless start_index.nil?
        result = result[start_index..-1]

        result.split(/\n/).each do |line|
          line.strip!
          if match = line.match(/^Duration: ((\d\d):(\d\d):(\d\d(.\d)?)), .*, bitrate: (\d+) kb\/s/)
            puts "found duration #{line}"
            ffmpeg_values[:container] = {:type => :container}
            if match[1]
              hours = match[2] ? match[2].to_i : 0
              minutes = match[3] ? match[3].to_i : 0
              seconds = match[4] ? match[4].to_f : 0
              ffmpeg_values[:container][:length] = (hours * 60 * 60) + (minutes * 60) + seconds
            end
            if match[6]
              ffmpeg_values[:container][:bitrate] = match[6].to_i * 1000
            end
          elsif match = line.match(/^Stream #0.(\d).*: Video: ([^,]*)(, [^,]*)?(, (\d+)x(\d+))(, (\d+.\d+) fps)?/)
            puts "found video #{line}"
            track_info = ffmpeg_values["track_#{match[1]}".to_sym] = {:type => :video}
            if match[2]
              track_info[:codec] = match[2]
            end
            if match[5]
              track_info[:width] = match[5]
            end
            if match[6]
              track_info[:height] = match[6]
            end
            if match[8]
              track_info[:fps] = match[8]
            end        
          elsif match = line.match(/^Stream #0.(\d).*: Audio: ([^,]*)(, (\d+) Hz)?(, (mono|stereo))?(, (\d+) kb\/s)?/)
            puts "found audio #{line}"
            track_info = ffmpeg_values["track_#{match[1]}".to_sym] = {:type => :audio}
            if match[2]
              track_info[:codec] = match[2]
            end
            if match[4]
              track_info[:rate] = match[4]
            end
            if match[6]
              if match[6] == 'stereo'
                track_info[:channels] = 2
              elsif match[6] == 'mono'
                track_info[:channels] = 1
              end
            end
            if match[8]
              track_info[:bitrate] = match[8].to_i * 1000
            end
          elsif match = line.match(/^Stream #0.(\d).*: Data: (.*)/)
            puts "found data #{line}"
            track_info = ffmpeg_values["track_#{match[1]}".to_sym] = {:type => :data}
          else
            puts "found other #{line}"
          end
        end

        @tracks = MediaFileAttributes.parse_values(ffmpeg_values)
      end
    end

    def self.create_thumbnail(file_path, width, height, time)
      thumbnail_file_path = "#{file_path}.jpg"
      commandline = []
      commandline += BINARY
      commandline << '-ss'
      commandline << time.to_s
      commandline << '-i'
      commandline << file_path
      commandline += ['-f', 'mjpeg', '-deinterlace', '-vframes', '1', '-an', '-y', '-s']
      commandline << "#{width}x#{height}"
      commandline << thumbnail_file_path

      puts "trying to run: #{commandline.join(' ')}"
      result = begin
        timeout(60) do
          Open3.popen3(*commandline) do |i, o, e|
            [o.read, e.read]
          end
        end
      rescue Timeout::Error => e
        puts "Timeout reached when inspecting #{file_path} with ffmpeg"
        raise e
      end
      thumbnail_file = File.new(thumbnail_file_path)
      if thumbnail_file.stat.size == 0
        FileUtils.rm_f(thumbnail_file.path)
        throw result.join
      end

      return thumbnail_file
    end
  end

  class MplayerIntegrator
    attr_accessor :tracks
    BINARY = ["mplayer"]
    OPTIONS = ["-identify", "-vo", "null", "-ao", "null", "-frames", "0", "-really-quiet", "-msgcharset", "utf8"]
    TIMEOUT = 60

    MPLAYER_TRACK_FIELD_MAP = {
      'CODEC' => :codec,
      'WIDTH' => :width,
      'HEIGHT' => :height,
      'FORMAT' => :format,
      'ASPECT' => :aspect,
      'ID' => :id,
      'BITRATE' => :bitrate,
      'FPS' => :fps,
      'FILENAME' => :file_name,
      'LENGTH' => :length,
      'DEMUXER' => :demuxer,
      'RATE' => :rate,
      'NCH' => :channels
    }

    def initialize(file_path)
      commandline = []
      commandline += BINARY
      commandline += OPTIONS
      commandline += [file_path]
      puts "trying to run: #{commandline.join(' ')}"
      result = begin
        timeout(TIMEOUT) do
          Open3.popen3(*commandline) do |i, o, e|
            [o.read, e.read]
          end
        end
      rescue Timeout::Error => e
        puts "Timeout reached when inspecting #{file_path} with mplayer"
        raise e
      end

      raise "mplayer error when inspecting #{file_path}: #{result.last}" if result.first.empty? && !result.last.empty?

      mplayer_values = {:container => {:type => :container}}

      match = result.first.match(/.*ID_AUDIO_ID=(\d).*/)
      audio_track = mplayer_values["track_#{match[1]}".to_sym] = {:type => :audio} unless match.nil?

      match = result.first.match(/.*ID_VIDEO_ID=(\d).*/)
      video_track = mplayer_values["track_#{match[1]}".to_sym] = {:type => :video} unless match.nil?

      result.first.split(/\n/).each do |line|
        #puts line
        if (match = line.match(/ID_([^_]+)(_([^=].*))?=(.*)/))
          if match[3]
            key = MPLAYER_TRACK_FIELD_MAP[match[3]] || match[3]
          else
            key = MPLAYER_TRACK_FIELD_MAP[match[1]] || match[1]
          end
          case match[1]
          when 'VIDEO'
            video_track[key] = match[4]
          when 'AUDIO'
            audio_track[key] = match[4]
          else
            mplayer_values[:container][key] = match[4]
          end
        end
      end

      @tracks = MediaFileAttributes.parse_values(mplayer_values)
    end
  end

  class AtomicParsleyIntegrator
    attr_reader :values, :tracks
    BINARY = ["AtomicParsley"]
    OPTIONS = ['-T', '1']
    TIMEOUT = 60

    def initialize(file_path)
      commandline = []
      commandline += BINARY
      commandline += [file_path]
      commandline += OPTIONS
      puts "trying to run: #{commandline.join(' ')}"
      result = begin
        timeout(TIMEOUT) do
          Open3.popen3(*commandline) do |i, o, e|
            o.read
          end
        end
      rescue Timeout::Error => e
        puts "Timeout reached when inspecting #{file_path} with AtomicParsley"
        raise e
      end

      @tracks = {:container => {:type => :container, :ipod_uuid => false}}

      atomic_parsley_values = Hash.new

      if result =~ /Atom uuid=6b6840f2-5f24-4fc5-ba39-a51bcf0323f3/
        @tracks[:container][:ipod_uuid] = true
        atomic_parsley_values[:ipod_uuid] = true
      end
      @values = atomic_parsley_values
    end
  end

  class ExifToolIntegrator
    attr_accessor :aspect_ratio, :poster_time, :width, :height
    BINARY = ["exiftool"]
    OPTIONS = ["-q", "-q", "-s", "-t"]
    TIMEOUT = 60

    def initialize(file_path)
      commandline = []
      commandline += BINARY
      commandline += OPTIONS
      commandline += [file_path]
      puts "trying to run: #{commandline.join(' ')}"
      result = begin
        timeout(TIMEOUT) do
          Open3.popen3(*commandline) do |i, o, e|
            o.read
          end
        end
      rescue Timeout::Error => e
        puts "Timeout reached when inspecting #{file_path} with ExifTool"
        raise e
      end

      @values = Hash.new

      result.split(/\n/).each do |line|
        line.strip!
        if match = line.match(/([^\t]+)\t(.+)/)
          @values[match[1].underscore] = match[2]
        end
      end

      unless @values['aspect_ratio'].blank?
        aspect_ratio_match = @values['aspect_ratio'].match(/\d+:\d+/)
        aspect_ratio_match = aspect_ratio_match[0] if aspect_ratio_match
        case aspect_ratio_match
        when "16:9", "16/9"
          @aspect_ratio = MediaFileAttributes::ASPECT_RATIO_16_BY_9
        when "4:3", "4/3"
          @aspect_ratio = MediaFileAttributes::ASPECT_RATIO_4_BY_3
        end
      end

      unless @values['poster_time'].blank?
        poster_time_match = @values['poster_time'].match(/(\d+\.\d+)s/)
        @poster_time = poster_time_match[1].to_f if poster_time_match
      end

      unless @values['image_height'].blank?
        @height = @values['image_height'].to_i
      end

      unless @values['image_width'].blank?
        @width = @values['image_width'].to_i
      end
    end
  end
end
