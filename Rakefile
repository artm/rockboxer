require "fileutils"
require "active_support/inflector"
require 'yaml'

require "./fuzzy_locale"
I18n.locale = :fuzzy
require "./spread"

desc "Unmount the player"
task :umount do
  %x{umount #{mount_point}}
end

desc "Sync podcasts to the player"
task :sync => [:copy, :playlists]

desc "Copy podcasts to the player"
task :copy do
  copy_podcasts source, podcasts_path
end

desc "Update playlists on the device"
task :playlists do
  update_playlists mount_point
end

private

def mount_point
  "/media/artm/0123-4567"
end

def podcasts_path
  File.join mount_point, "PODCASTS"
end

def track_glob
  "*.{mp3,ogg}"
end

def space
  df_line = %x{df -k #{mount_point}}.split("\n").last
  df_line.split(/ +/)[3].to_i
end

def source
  "/home/artm/gPodder/Downloads"
end

def copy_podcasts source, podcasts_path
  left = space
  Dir.glob("#{source}/**/*.mp3").sort_by do |path|
    File.mtime(path)
  end.each do |path|
    file_size = File.size(path) / 1000
    if left > file_size
      left -= file_size
      dst = path.sub(/^#{source}/, podcasts_path)
      dst = ActiveSupport::Inflector.transliterate(dst, "_")
      puts dst
      unless File.exists? dst
        FileUtils.mkdir_p( File.dirname dst )
        FileUtils.mv( path, dst )
      end
    end
  end
end

def update_playlists root
  playlists_dir = File.join root, "Playlists"
  podcasts_dir = File.join root, "PODCASTS"
  config_file = File.join podcasts_dir, "podcasts.yml"
  config = {}
  config = YAML.load_file config_file if File.exists? config_file
  FileUtils.mkdir_p playlists_dir
  groups = config["groups"] || {}
  groups = make_group_regexes groups
  tracks = find_tracks(podcasts_dir, groups)
  tracks = Hash[ tracks.map do |group,list|
    list = list.map{|track| track.sub(%r[#{root}/*],"/")}
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
    tracks[group] += Dir[File.join(subdir, track_glob)]
    tracks
  end
end

def spread_by_dirname tracks
  Spread.spread *tracks.group_by{|track| File.dirname track}.values
end
