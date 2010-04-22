#!/usr/bin/env ruby
# Warhammer parsing script
#
gid = "1226"
sid = "2"

# requirements
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
chars = {}
ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql',
  :host => ENV['MYSQL_HOST'],
  :username => ENV['MYSQL_USER'],
  :password => ENV['MYSQL_PASS'],
  :database => ENV['MYSQL_DB']
)
class Character < ActiveRecord::Base
 
end
class Charparse
  attr_accessor :name, :level, :idtag, :status, :career
  def initialize(name, level, status, career, idtag)
    @name = name
    @level = level
    @status = status
    @career = career
    @idtag = idtag
  end
end

chars = {}
unless Character.table_exists?
  ActiveRecord::Schema.define do
    create_table :Characters do |table|
      table.column :idtag, :string
      table.column :name, :string
      table.column :career, :string
      table.column :level, :string
      table.column :exp, :string
      table.column :rr, :string
      table.column :rrexp, :string
      table.column :status, :string
      table.column :gid, :string
      table.column :sid, :string
      table.column :timestamp, :timestamp
    end
  end
end

# Load guild webpage status and update DB
searchurl = "https://realmwar.warhammeronline.com/realmwar/GuildInfo.war?id=#{gid.to_s}&server=#{sid.to_s}"
guildpage = Hpricot.parse(Net::HTTP.get(URI.parse(searchurl)))
guildpage.search(" //div/table[@summary='Guild Roster']/tbody ").each_with_index do |line, index|
  charsearch = Hpricot.parse(line.to_s)
  status = (charsearch/:img).first[:title]
  status = status.match(/O[fn]{1,2}line/)
  name = (charsearch/:a).inner_html
  idtag = (charsearch/:a).first[:href]
  idtag = idtag.match(/\d{3,10}/)
  career = (charsearch/:img).last[:title]
  level = (charsearch/:td).last.inner_html
  chars[index] = Charparse.new(name.to_s, level.to_s, status.to_s, career.to_s, idtag.to_s)
  if Character.exists?(:idtag => idtag.to_s)
    Character.update_all("status='#{status.to_s}', level='#{level.to_s}'", :idtag => idtag.to_s)
  else
    Character.create(:idtag => idtag.to_s, :name => name.to_s, :career => career.to_s, :level => level.to_s, :status => status.to_s, :gid => gid.to_s, :sid => sid.to_s)
  end
end

# Clean up those not in the guild anymore
Character.all.each do |line|
  delete = 1
  chars.each_with_index do |charsearch, index|
    delete = 0 if chars[index].idtag  == line.idtag
  end
  Character.delete_all("idtag = #{line.idtag}") if delete == 1
end
