require "rubygems"
require "ruby-prof"
require "search_engine.rb"
require "search_engine"
require 'ruby-growl'

search_engine = SearchEngine.new('./test2/file*','stoplist.txt')

ARGF.each do |line|
  words = line.split
  if(words.size >= 1)
    exit if words[0] == "ZZZ"
    search_engine.query(words)
  else
    puts "Enter a query or type 'ZZZ' to end."
  end
end