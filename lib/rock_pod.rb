require "pathname"
require "fileutils"
require 'yaml'

require "spread"

module RockPod
  BLOCK_SIZE = 512
  KEEP_AVAILABLE_BYTES = 500_000

  def copy_podcasts
    gpodder_tracks(source_dir, glob).sort_by do |path|
      File.mtime(path)
    end.reduce( available_blocks - keep_available_blocks ) do |blocks_left,path|
      file_size = file_size_in_blocks path
      break unless blocks_left > file_size
      move_file path
      blocks_left - file_size
    end
  end

  def update_playlists
    groupped = groups.group_tracks rockbox_tracks
    groupped.each do |group, list|
      groupped[group] = spread_by_dirname(list.map{|track| player_path track})
    end
    groupped["podcasts"] = Spread.spread *groupped.values

    FileUtils.mkdir_p playlists_dir
    groupped.each {|group,tracks| save_playlist group, tracks }
  end

  def keep_available_blocks
    KEEP_AVAILABLE_BYTES / BLOCK_SIZE
  end

  def gpodder_tracks
    Dir.glob("#{PODCASTS_SOURCE}/*/#{TRACKS_GLOB}")
  end

  def rockbox_tracks
    Dir.glob("#{PODCASTS_DESTINATION}/*/#{TRACKS_GLOB}")
  end

  def file_size_in_blocks path
    File.size(path) / BLOCK_SIZE
  end

  def available_blocks
    df_line = %x{df -B #{BLOCK_SIZE} #{MOUNT_POINT}}.split("\n").last
    df_line.split(/ +/)[3].to_i
  end

  def relative_path dir, path
    Pathname(path).relative_path_from(Pathname(dir)).to_s
  end

  def player_path track
    File.join "/", relative_path(MOUNT_POINT, track)
  end

  def move_file source
    relative = sanitize_path(relative_path PODCASTS_SOURCE, source)
    puts "+ #{relative}"
    destination = File.join( PODCASTS_DESTINATION, relative )
    FileUtils.mkdir_p File.dirname destination
    FileUtils.mv source, destination
  end

  def sanitize_path path
    path.gsub(/[»]+/,"_")
  end

  def save_playlist group, tracks
    m3u_path = File.join playlists_dir, group + ".m3u"
    puts "%4d tracks @ %s" % [tracks.count, group]
    File.open(m3u_path, "w") { |io| io.puts tracks }
  end

  def playlists_dir
    File.join MOUNT_POINT, "Playlists"
  end

  def podcasts_dir
    File.join MOUNT_POINT, "PODCASTS"
  end

  def config_file
    File.join podcasts_dir, "podcasts.yml"
  end

  def load_config
    if File.exists? config_file
      YAML.load_file config_file
    else
      {}
    end
  end

  def config
    @config ||= load_config
  end

  def groups
    @groups ||= (make_group_regexes config["groups"] || {}).extend TrackGroups
  end

  def make_group_regexes groups
    groups.map{|name,patterns| [name,Regexp.union(patterns)]}
  end

  module TrackGroups
    def group_tracks tracks
      tracks.reduce(list_hash) do |groupped,track|
        group = track_group track
        groupped[group] << track
        groupped
      end
    end

    def track_group track
      dir = File.basename File.dirname track
      group, pattern = find{|group,pattern| pattern =~ dir}
      group || "misc"
    end

    def list_hash
      Hash.new {|hash,key| hash[key] = []}
    end
  end

  def spread_by_dirname tracks
    Spread.spread *tracks.group_by{|track| File.dirname track}.values
  end

end
