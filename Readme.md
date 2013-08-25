# Rockboxer

I use this to manage podcasts on my Rockbox music player.

Once the device is automounted (or manually mounted by clicking it in Nautilus,
I'm not sure why automounting doesn't always work), I can issue

    rake sync
    rake unmount

to do the following:

1. sort the new podcasts in gPodder's downloads folder on modification time
2. copy in that order while there is still some space on the device
3. update podcasts playlists making sure episodes from the same feed are spread
   apart if possible

I maintain several "podcast group" playlists and a master "podcasts" playlist
with all available episodes. The groups are configured in the file
"/PODCASTS/podcasts.yml" on the device. The file looks like:

    groups:
      science:
        - 60-Second
        - Биоразно
        - Naked
        - Science
        - Future
      tech:
        - Giant Robots
        - Ruby
        - Javascript
        - Linux
        - Ubuntu
      fiction:
        - Sigler
        - Tales
        - StarShipSofa

where the key in the `groups` hash is the group name and a value is a list of
patterns, matched against the feed folder.

The master playlist is ordered so that episodes from a group are spread apart if
possible (like individual feeds are spread in a group playlist).

The spreading is a personal preference stemming from my listening habits.
