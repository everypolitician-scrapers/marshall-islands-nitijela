#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraperwiki'
require 'scraped'
require 'nokogiri'

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
    %w(H.E. Hon. Minister Senator President Vice Speaker).each do |prefix|
      name.gsub!(prefix, '')
    end

    if role !~ /President|Speaker|Minister/
      constituency = role
      role = ''
    end

    data = {
      name:         name.tidy,
      party:        'None',
      role:         role,
      constituency: constituency,
      term:         '2012',
      source:       url,
    }
    # puts data
    ScraperWiki.save_sqlite(%i(name term), data)
  end
end

scrape_list('http://www.rmiparliament.org/members')
