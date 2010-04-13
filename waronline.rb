#!/usr/bin/ruby
#
## Runtime Variables

guildid=1226
serverid=2

$mysqlhost="localhost"
$mysqlusername="XX"
$mysqlpassword=""
$mysqlDB="" 

## Static Variables
$chars =  {}
$charcount=0
$debug=3

## Required modules
require 'net/http'
require 'mysql'

## Objects
class Character
	def initialize(cname, level, id, gid, sid, indb, status)
		@cname = cname
		@level = level
		@id = id
		@gid = gid
		@sid = sid
		@indb = indb
		@status = status
	end
	def to_s
		"Character: #@cname, #@level\n"
	end
	attr_writer :rr, :id, :chcl, :exp, :rrexp, :sid, :gid, :indb
	attr_reader :cname, :level, :rr, :id, :chcl, :exp, :rrexp, :sid, :gid, :status, :indb, :sid
end

## Functions
def strip_html(str)
	str = str.strip || ''
	str.gsub(/<\/?[^>]*>/, '')
end

def load_warstatus(gid, sid)
	gid=gid.to_s
	sid=sid.to_s
	searchurl = "https://realmwar.warhammeronline.com/realmwar/GuildInfo.war?id=#{gid}&server=#{sid}"
	Net::HTTP.get(URI.parse(searchurl))
end

def load_list(parse, gid, sid)
	gid=gid
	sid=sid
	onlinename="blank"
	status=""
	found="none"
	count="blank"
	level="blank"
	id="0"
	parse.each do |line|
	        if count == "2"
        	        level = strip_html(line)
			indb="no"
			$chars[$charcount] = Character.new(onlinename, level, id, gid, sid, indb, status)
                	count = "0"
        	end
        	if count == "1"
                	count = "2"
        	end
        	if found == "one"
			id = line.match(/\d{3,10}/)
			onlinename=strip_html(line)
                	count="1"
			found="none"
        	end
        	if /player-status_online/ =~ line
                	found="one"
			status="online"
                	$charcount = $charcount + 1
        	end

	end
end

def insert_chars
	y=1
	my = Mysql.real_connect($mysqlhost, $mysqlusername, $mysqlpassword, $mysqlDB)
	$chars.each do
		id=$chars[y].id
		status=$chars[y].status
		query="SELECT * FROM onlinechars WHERE id LIKE #{id.to_s}"
		res = my.query(query)
		res.each do |row|
			if row[7] != status
				print row[7]
				queryx="UPDATE onlinechars SET status='#{status.to_s}' WHERE id='#{id.to_s}';"
				empty = my.query(queryx)
			end
		end
		y=y+1
	end
	my.close
end

## Main
begin
	warprint = load_warstatus(guildid, serverid)
	load_list(warprint, guildid, serverid)
	insert_chars
end
