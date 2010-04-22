#!/usr/bin/env ruby
# Warhammer parsing script
#

# requirements
require 'net/http'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'

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

Character.all.each do |char|
  rrexp = "" # stupid variable gets locked in the loop only
  doc = Nokogiri::HTML(Net::HTTP.get(URI.parse("https://realmwar.warhammeronline.com/realmwar/CharacterInfo.war?id=#{char.idtag}&server=#{char.sid}")))
  exp = doc.search("//div[@class='progress-desc']").first.inner_html
  rr = doc.search("//div[@class='number']").last.inner_html
  doc.search("//div[@class='progress-desc']").last.inner_html.each do |line|
    rrexp = line.strip || ""  if /Current\sRenown/ =~ line
  end
  Character.update_all("exp='#{exp}', rrexp='#{rrexp}', rr='#{rr}'", :idtag => char.idtag)
end
