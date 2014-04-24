$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rock_pod'
include RockPod

MOUNT_POINT = "/media/artm/ROCKBOX_4G"
PODCASTS_DESTINATION = File.join MOUNT_POINT, "PODCASTS"
TRACKS_GLOB = "*.{mp3,ogg}"
PODCASTS_SOURCE = "/home/artm/Sync/Pod/podcasts"
UMOUNT_POINTS = [MOUNT_POINT, "/media/artm/MUSIC_8G"]

desc "Unmount the player"
task :umount do
  umount
end

desc "Sync podcasts to the player"
task :sync => [:copy, :playlists]

desc "Copy podcasts to the player"
task :copy do
  puts "\nMoving podcast episodes to the player"
  copy_podcasts
end

desc "Update playlists on the device"
task :playlists do
  puts "\nUpdating playlists"
  update_playlists
end
