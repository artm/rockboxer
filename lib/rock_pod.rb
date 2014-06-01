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

  def keep_available_blocks
    KEEP_AVAILABLE_BYTES / BLOCK_SIZE
  end

  def gpodder_tracks
    Dir.glob("#{PODCASTS_SOURCE}/*/#{TRACKS_GLOB}")
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

end
