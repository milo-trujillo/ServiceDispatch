# encoding: UTF-8
require 'sinatra/base'
require 'redis'

=begin
	The website is powered by two queries, to the redis dictionaries for
	"durations" and "timestamps". The key is the clip's timestamp in epoch
	time, which makes them unique and sortable. We pass the sorted keys
	and both dictionaries to the web template, which stuffs them in a
	table. There's also a page hit counter for funzies.
=end

class Dispatch < Sinatra::Base
	error Sinatra::NotFound do
		return "ERROR: Not found"
	end

	get '/' do
		redis = Redis.new()
		redis.incr("hits")
		durations = redis.hgetall("durations")
		timestamps = redis.hgetall("timestamps")
		keys = durations.keys.sort.reverse.first(30)
		erb :index, :locals => {:keys => keys, :durations => durations, :timestamps => timestamps, :title => "30 Most Recent Broadcasts"}
	end

	get '/day' do
		redis = Redis.new()
		redis.incr("hits")
		durations = redis.hgetall("durations")
		timestamps = redis.hgetall("timestamps")
		now = Time.now.to_i
		yesterday = (now - 86400).to_s
		keys = durations.keys.select{|k| k >= yesterday }.sort.reverse
		erb :index, :locals => {:keys => keys, :durations => durations, :timestamps => timestamps, :title => "Broadcasts from past 24 hours"}
	end

	get '/all' do
		redis = Redis.new()
		redis.incr("hits")
		durations = redis.hgetall("durations")
		timestamps = redis.hgetall("timestamps")
		keys = durations.keys.sort.reverse
		erb :index, :locals => {:keys => keys, :durations => durations, :timestamps => timestamps, :title => "All Broadcasts"}
	end
end
