require "pathname"
require "fileutils"
require 'yaml'

require "spread"

module RockPod
  def umount
    %x{umount #{MOUNT_POINT}}
  end

  def space
    df_line = %x{df -k #{MOUNT_POINT}}.split("\n").last
    df_line.split(/ +/)[3].to_i
  end

  def relative_path dir, path
    Pathname(path).relative_path_from(Pathname(dir)).to_s
  end

  def move_file source
    relative = relative_path PODCASTS_SOURCE, source
    puts relative
    destination = File.join( PODCASTS_DESTINATION, relative )
    FileUtils.mkdir_p File.dirname destination
    FileUtils.mv source, destination
  end

  def copy_podcasts
    left = space
    Dir.glob("#{PODCASTS_SOURCE}/**/#{TRACKS_GLOB}").sort_by do |path|
      File.mtime(path)
    end.each do |path|
      file_size = File.size(path) / 1000
      break unless left > file_size
      left -= file_size
      move_file path
    end
  end

  def update_playlists
    playlists_dir = File.join MOUNT_POINT, "Playlists"
    podcasts_dir = File.join MOUNT_POINT, "PODCASTS"
    config_file = File.join podcasts_dir, "podcasts.yml"
    config = {}
    config = YAML.load_file config_file if File.exists? config_file
    FileUtils.mkdir_p playlists_dir
    groups = config["groups"] || {}
    groups = make_group_regexes groups
    tracks = find_tracks(podcasts_dir, groups)
    tracks = Hash[ tracks.map do |group,list|
      list = list.map{|track| track.sub(%r[#{MOUNT_POINT}/*],"/")}
      [ group, spread_by_dirname(list) ]
    end ]
    tracks["podcasts"] = Spread.spread *tracks.values
    tracks.each do |list,tracks|
      m3u_path = File.join playlists_dir, list + ".m3u"
      File.open(m3u_path, "w") do |io|
        io.puts tracks
      end
    end
  end

  def make_group_regexes groups
    groups.map{|name,patterns| [name,Regexp.union(patterns)]}
  end

  def find_tracks root, groups
    Dir[File.join(root, "*/")].inject({}) do |tracks,subdir|
      group,pattern = groups.find{|group,pattern| pattern =~ subdir}
      group ||= 'misc'
      tracks[group] ||= []
      tracks[group] += Dir[File.join(subdir, TRACKS_GLOB)]
      tracks
    end
  end

  def spread_by_dirname tracks
    Spread.spread *tracks.group_by{|track| File.dirname track}.values
  end

end
