#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)

  noko.css('div.item-page').xpath('.//p[contains(.,".....")]').each do |mp|
    name, role = mp.text.split(/\.{3,}/)
    name = name.gsub('H.E. ','').gsub('Hon. ','').gsub('Minister ','').gsub('Senator ','')
    if role !~ /President|Speaker|Minister/
      constituency = role
      role = ''
    end

    data = { 
      name: name.strip,
      party: "None",
      role: role,
      constituency: constituency,
      term: '2012',
      source: url,
    }
    puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

scrape_list('http://www.rmiparliament.org/members?tmpl=component&print=1&page=')
