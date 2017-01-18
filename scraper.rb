#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'fuzzy_match'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

@parties = {
  'AKA' => 'Aelon Kein Ad',
  'KEA' => 'Kien Eo Am',
  'UPP' => "United People's Party",
  'UDP' => 'United Democratic Party',
  'IND' => 'Independent',
}

def party_info(text)
  if text =~ /(.*?)\s+\((.*?)\)/
    [Regexp.last_match(1), Regexp.last_match(2), @parties[Regexp.last_match(2)]]
  else
    raise "No party in #{text}"
  end
end

def scrape_list(url, wpdata)
  noko = noko_for(url)

  fuzzer = FuzzyMatch.new(wpdata.map { |m| m[:name] })

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
      name:         name.strip,
      party:        'None',
      role:         role,
      constituency: constituency,
      term:         '2012',
      source:       url,
    }
    fuzzed = fuzzer.find(data[:name]) or raise "no good match for #{data[:name]}"
    wp = wpdata.find { |p| p[:name] == fuzzed }
    wp.delete :name
    data.merge!(wp)
    puts data
    ScraperWiki.save_sqlite(%i(name term), data)
  end
end

def scrape_wikipedia(url)
  noko = noko_for(url)
  wpdata = noko.xpath('.//h2[contains(.,"Members")]/following-sibling::ul[1]/li').map do |line|
    links = Hash[line.css('a').drop(1).map do |e|
      [e.text, URI.join(url, e.attr('href')).to_s]
    end]

    area, who = line.text.split(' - ')
    members = who.split(/,\s*/)
    members.map do |m|
      name, party_id, party = party_info(m)
      {
        name:         name,
        party_id:     party_id,
        party:        party,
        constituency: area,
        wikipedia:    links[name],
      }
    end
  end
end

wpdata = scrape_wikipedia('https://en.wikipedia.org/w/index.php?title=Legislature_of_the_Marshall_Islands&oldid=672387367').flatten
scrape_list('http://www.rmiparliament.org/members', wpdata)
