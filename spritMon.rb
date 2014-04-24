#!/usr/bin/env ruby

require 'json'
require 'net/http'

#config
lat = 48.714692
long = 9.089853
radius = 4
showOnly = ['ElaBo',  'PuQi', '6L8MF']
displayName = { "ElaBo" => 'JET Industriestrasse', "PuQi" => "Aral RobertKochStrasse", "6L8MF" => "Shell Industriestrasse" }

hostname=`hostname -f`.gsub("\n", "")
interval=-60

class Tankstelle
  attr_accessor :id, :diesel, :e5, :e10, :name, :strasse, :ort

  def initialize(id, diesel, e5, e10, name, strasse, ort)
    @id = id
    @diesel = diesel
    @e5 = e5
    @e10 = e10
    @name = name
    @strasse = strasse
    @ort = ort
  end
end

def getData(lat, long, radius)
  url = "http://www.tanke-guenstig.de/Benzinpreise/ajax/area?c=#{lat}%2C#{long}&r=#{radius}"
  resp = Net::HTTP.get_response(URI.parse(url))
  data = resp.body
  result = JSON.parse(data)

  if result.has_key? 'Error'
    raise "web service error"
  end
  return result
end

data = getData(lat, long, radius)

objects = data['d'].map { |tk| Tankstelle.new( tk['h'], tk['pr']['d'], tk['pr']['e5'], tk['pr']['e10'], tk['na'], tk['addr']['street'], tk['addr']['city'] ) }

config = (ARGV[0] == "config")
dump = (ARGV[0] == "dump")
collectd = (ARGV[0] == "collectd")

if config then
  print "graph_title Benzinpreise\n"
  print "graph_vlabel EUR\n"
  print "graph_scale yes\n"
  print "graph_category car\n"
end

objects.each {|t|
  if displayName[t.id] then
    t.name = displayName[t.id]
  end
  if dump then
    p t
  else
    if showOnly.include? t.id then
      if collectd then
        print "PUTVAL #{hostname}/benzinpreis-sb/absolute-#{t.name.gsub(" ","_")} interval=#{interval} N:#{t.diesel.gsub(".", "")}\n"
      else
        if config then 
          print "#{t.id}.label #{t.name}\n"
        else
          print "#{t.id}.value #{t.diesel}\n"
        end
      end
    end
  end
}
