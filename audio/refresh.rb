#!/usr/bin/env ruby
require 'redis'
require 'set'
require 'fileutils'
require 'audioinfo'

=begin
	This script looks for new audio files in the current directory
	For each file it checks the creation time, and if it's a file
	we haven't seen before, determines the duration, saves all
	this data to redis, and copies the clip to the public website
=end

DestDir = __dir__ + "/../public/audio/"

redis = Redis.new()
clips = Set.new(redis.hgetall("durations").keys)
mp3s = Dir.glob(__dir__ + "/troy*mp3")
for mp3 in mp3s
	ctime = File.ctime(mp3).to_i
	readable_ctime = File.ctime(mp3).to_s
	if( ! clips.include?(ctime) ) # New file!
		begin
			AudioInfo.open(mp3) do |info|
				duration = info.length
				duration_mins = duration / 60
				duration_secs = duration % 60
				duration_s = sprintf("%02d:%02d", duration_mins, duration_secs)
				#puts("Found track '#{mp3}' of duration #{duration_s}")
				redis.hset("durations", ctime.to_s, duration_s)
				redis.hset("timestamps", ctime.to_s, readable_ctime)
				#FileUtils.ln_s(mp3, "#{DestDir}/#{ctime}.mp3")
				FileUtils.cp(mp3, "#{DestDir}/#{ctime}.mp3")
			end
		rescue Exception => e
			# Skip the audio clip if it's still being written
			puts("Crash: #{e.message}")
		end
	end
end
