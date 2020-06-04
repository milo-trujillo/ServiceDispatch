#!/usr/bin/env ruby
require 'redis'
require 'set'
require 'fileutils'
require 'audioinfo'

=begin
	This script is responsible for all audio:
		* Downloading the stream
		* Chopping the stream into conversations
		* Detecting when a conversation is saved
		* Adding that conversation to the database
=end

# Configurable parameters
MetaURL ="https://www.broadcastify.com/scripts/playlists/1/15434/-6364839436.m3u" # Set this to the playlist URL if the audio stream changes periodically
URL="" # Set this if no metaurl is necessary
DestDir = __dir__ + "/../public/audio/" # Website's audio folder
Silence="-42db" # Determine this through trial and error
Pause="5.0" # How long a pause before we mark a conversation as ended
StreamType = "mp3" # Audio file type must be supported by sox and audioinfo!!
Pipe="pipe.#{StreamType}" # Used to communicate between curl and sox
ClipCheckFrequency = 60 # How frequently to check for new audio clips, in seconds

=begin
	This function looks for new audio files in the current directory
	For each file it checks the creation time, and if it's a file
	we haven't seen before, determines the duration, saves all
=end
def checkNewClips
	redis = Redis.new()
	clips = Set.new(redis.hgetall("durations").keys)
	mp3s = Dir.glob(__dir__ + "/dispatch*#{StreanType}")
	for mp3 in mp3s
		ctime = File.ctime(mp3).to_i
		readable_ctime = File.ctime(mp3).to_s
		if( ! clips.include?(ctime) ) # New file!
			inUse = `lsof #{mp3}`.size > 0
			if( inUse )
				next # Skip files sox is still writing to
			end
			begin
				AudioInfo.open(mp3) do |info|
					duration = info.length
					duration_mins = duration / 60
					duration_secs = duration % 60
					duration_s = sprintf("%02d:%02d", duration_mins, duration_secs)
					redis.hset("durations", ctime.to_s, duration_s)
					redis.hset("timestamps", ctime.to_s, readable_ctime)
					FileUtils.cp(mp3, "#{DestDir}/#{ctime}.mp3")
					File.delete(mp3)
				end
			rescue Exception => e
				# Skip the audio clip if it's still being written
				puts("Crash: #{e.message}")
			end
		end
	end
end

=begin
	The main program fires off threads to:
		* Download audio
		* Run sox (which chops audio on silence)
		* Check for new audio files and add them to database
	If sox crashes (usually because curl crashed and closed the fifo) we
	kill the other threads and restart.
=end
if __FILE__ == $0
	loop {
		# Clear the pipe in case there's old audio data in there
		File.delete(Pipe) if File.exist?(Pipe)
		File.mkfifo(Pipe)
		url = URL
		# If there's a meta-url, extract the audio stream url
		# otherwise, just use the provided stream url
		if( MetaURL.length > 0 )
			url = `curl -L --silent #{MetaURL} | grep http | tr -d " \t\n\r"`
		end
		stream = Thread.new { system("curl -L --silent \"#{url}\" > #{Pipe}") }
		refresh = Thread.new { 
			loop { 
				sleep(ClipCheckFrequency) 
				begin
					checkNewClips
				rescue Exception => e
					puts("Crashed checking for new clips: #{e.message}")
				end
			}
		}
		system("sox -V3 -t #{StreamType} #{Pipe} dispatch_part_.#{StreamType} silence 1 0.5 #{Silence} 1 #{Pause} #{Silence} : newfile : restart")
		# We won't pass this line unless sox crashes
		# and sox usually crashes because the audio stream failed
		# so we'll rebuild the audio stream and try again...
		Thread.kill(stream)
		Thread.kill(refresh)
	}
end
