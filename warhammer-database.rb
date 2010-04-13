#!/usr/bin/ruby
#
## Runtime Variables

guildid=1226
serverid=2

$mysqlhost="localhost"
$mysqlusername=""
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
	attr_accessor :level, :rr, :id, :chcl, :exp, :rrexp, :sid, :gid, :status, :indb, :cname, :event, :rhand, :banner, :trophy1, :trophy, :trophy4, :trophy5, :body, :gloves, :boots, :helm, :shoulders, :shirt, :pants, :back, :belt, :accessory1, :accessory2, :accessory2, :accessory4
	def initialize(cname, level, id, gid, sid, indb, status)
		@cname = cname
		@level = level
		@id = id
		@gid = gid
		@sid = sid
		@indb = indb
		@status = status
	end
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

def load_character_ids
	x=1
	$chars.each do
		pass="yes"
		id = $chars[x].id
		sid = $chars[x].sid
		searchurl = "https://realmwar.warhammeronline.com/realmwar/CharacterInfo.war?id=#{id.to_s}&server=#{sid.to_s}"

		page = Net::HTTP.get(URI.parse(searchurl))
		y=0
		i=0
		s=0
		page.each do |line|
			if /class="number"/ =~ line
				pass="no"
			end
			if pass == "no"
				if /class="number"/ =~ line
					$chars[x].rr = strip_html(line)
				end
			end
			if /Badlands/ =~ line
				chcl = strip_html(line)
				chcl = chcl.match(/[A-Za-z]{3,15}\s?[A-Za-z]{1,10}/)
				$chars[x].chcl = chcl.to_s
			end
			if /progress-desc">C/ =~ line
				exp = strip_html(line)
				$chars[x].exp = exp
			end
			if /Current\sRenown/ =~ line
				rr = strip_html(line)
				$chars[x].rrexp = rr
			end

=begin this section isn't gonna wokr fucking mythic
			s=1 if /slot-9-hover/ =~ line
			s=2 if /slot-24-hover/ =~ line
			s=3 if /slot-20-hover/ =~ line
			s=4 if /slot-21-hover/ =~ line
			s=5 if /slot-28-hover/ =~ line
			s=6 if /slot-22-hover/ =~ line
			s=7 if /slot-10-hover/ =~ line
			s=8 if /slot-11-hover/ =~ line	
			s=9 if /slot-27-hover/ =~ line
			s=10 if /slot-31-hover/ =~ line
			s=11 if /slot-32-hover/ =~ line
			s=12 if /slot-33-hover/ =~ line
			s=13 if /slot-34-hover/ =~ line
	
			if /equip-name/ =~ line
				$chars[x].accessory4 = strip_html(line) if y == 13
				$chars[x].accessory3 = strip_html(line) if y == 12
				$chars[x].accessory2 = strip_html(line) if y == 11
				$chars[x].accessory1 = strip_html(line) if y == 10
				$chars[x].back = strip_html(line) if y == 9
				$chars[x].lhand = strip_html(line) if y == 8
				$chars[x].rhand = strip_html(line) if y == 7
				$chars[x].feet = strip_html(line) if y == 6
				$chars[x].belt = strip_html(line) if y == 5
				$chars[x].hands = strip_html(line) if y == 4	
				$chars[x].chest = strip_html(line) if y == 3
				$chars[x].shoulders = strip_html(line) if y == 2
				$chars[x].healm = strip_html(line) if y == 1
				s=0
			end
=end

		end
		x=x+1
 	end
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
		if /player-status_offlineTEST/ =~ line
			found="one"
			status="offline"
			$charcount = $charcount + 1
	       	end

	end
end

def insert_chars
	y=1
	my = Mysql.real_connect($mysqlhost, $mysqlusername, $mysqlpassword, $mysqlDB)
	$chars.each do
		id=$chars[y].id
		cname=$chars[y].cname
		level=$chars[y].level
		exp=$chars[y].exp
		rr=$chars[y].rr
		rrexp=$chars[y].rrexp
		career=$chars[y].chcl
		status=$chars[y].status
		sid=$chars[y].sid
		gid=$chars[y].gid
		indb=$chars[y].indb
		if indb == "no"
			query="SELECT * FROM onlinechars WHERE id='#{id}';"
			res = my.query(query)
			res.each do |row|
				indb="yes" if row[0] == id
				query="UPDATE onlinechars SET level='#{level.to_s}', exp='#{exp.to_s}', rr='#{rr.to_s}', rrexp='#{rrexp.to_s}', status='#{status.to_s}' WHERE id='#{id.to_s}';"
				empty = my.query(query)

			end
		end

		if indb == "no"
			query="INSERT INTO onlinechars (id, cname, level, exp, rr, rrexp, career, status, sid, gid) VALUES "
			query=query + "('#{id}', '#{cname}', '#{level}', '#{exp}', '#{rr}', '#{rrexp}', '#{career}', '#{status}', '#{sid}', '#{gid}'); "
			st = my.query(query)
		end
		y=y+1
	end
	my.close
end

## Main
begin
	warprint = load_warstatus(guildid, serverid)
	load_list(warprint, guildid, serverid)
	load_character_ids
	insert_chars
end
