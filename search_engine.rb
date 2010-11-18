require "rubygems"
require "linalg"
require "pp"
require "ruby-growl"

class Array
  # from: http://snippets.dzone.com/posts/show/302
  # allows you to do this:
  # >> a = ["able", "baker", "charlie"]
  # >> a.to_hash_values {|v| a.index(v)}
  # => {0=>"able", 1=>"baker", 2=>"charlie"}
  def to_hash_values(&block)
    Hash[*self.collect { |v|
      [block.call(v), v]
    }.flatten]
  end

  def to_hash_keys(&block)
    Hash[*self.collect { |v|
      [v, block.call(v)]
    }.flatten]
  end

  # Turns a sparse vector into a dense 1/0 vector, e.g.
  # >> [1, 4, 5].to_dense(7)
  # => [0, 1, 0, 0, 1, 1, 0, 0]
  def to_dense(n)
    Array.new(n) {|x| self.include?(x) ? 1 : 0 }
  end
end

class SearchEngine
  attr_reader :word_list
  def initialize(dir_glob, stoplist)
    @g = Growl.new("localhost", "ruby-growl", ["ruby-growl Notification"])
    @word_list = Hash.new # This is our main wordlist
    @documents = Hash.new # Let's keep track of each docs' sizes
    @stop_list = File.read(stoplist).split # Words that don't count
    Dir[dir_glob].each do |document|
      # Let's read that document and get the words
      words_in_document = File.read(document).split_with_index(' ')
      # We want to remember this document's size. We'll need it later.
      @documents[document] = words_in_document.size
      # For every word in this document
      words_in_document.each do |word, location|
        word.stem! # we do some basic stemming
        # Let's add it to our "word list" 
        # along with what document it came from
        # and where in the document we saw it
        add(word, document, location) unless word_does_not_belong(word)
      end
    end
    @term_document_matrix = compute_term_document_matrix
  end
  
  def compute_term_document_matrix
    words_array = @word_list.sort
    # words array is like this:
    # [["brown", {"./test2/file01.txt"=>[6], "./test2/file02.txt"=>[4]}],
    #  ["dog", {"./test2/file01.txt"=>[12], "./test2/file02.txt"=>[0]}],
    #  ["jason", {"./test2/file02.txt"=>[10]}],
    #  ["quick", {"./test2/file01.txt"=>[0]}]]
    td_matrix = Array.new(words_array.size) { Array.new(@documents.size) {0}}
    count = 0
    puts "Indexing. Please wait..."
    words_array.each do |entry|
      count += 1
      #if count % 100 == 0
        @g.notify("ruby-growl Notification", "It Came From Ruby-Growl", count.to_s)
        puts '.'
      #end
      word = entry[0]
      docs = entry[1].keys.map {|doc| doc }
      docs.each do |doc|
        td_matrix[word_to_num(word)][doc_to_num(doc)] = tfidf(word, doc)
      end
    end
    puts "Ready!"
    td_matrix
  end
  
  def words_hash
    words = @word_list.sort.map{ |x| x.first}
    words.to_hash_keys {|x| words.index(x)}
  end
  
  # This method exists solely for the benefit of the grader who
  # might want to peek into my "word list" datastructure.
  # This will print the first n items in my word list.
  def print_word_list(a, b)
    puts "Count: #{@word_list.size}"
    begin
      @word_list.sort[a...b].each do |item|
        pp item
      end
    rescue
      @word_list.sort.each do |item|
        pp item
      end
    end
  end
  
  # Given a query like "space ship", we first split on spaces
  # Then find the terms in the hash table to create a sparse vector
  # We remove nils and then convert from a sparse vector to a dense vector
  def query_vector(query)
    query.map {|x| words_hash[x]}.compact.reject { |s| s.nil? }.to_dense(@word_list.size)
  end
  
  def query(query)
    c = Linalg::DMatrix.rows @term_document_matrix
    u, s, vt = c.singular_value_decomposition
    (2...s.dimensions.min).each do |x|
      s[x,x] = 0
    end
    ck = u*s*vt
    q = Linalg::DMatrix[query_vector(query)]
    results = (q * ck).to_a[0]
    results_with_index = []
    results.each_with_index do |item, idx|
      results_with_index << [idx, item]
    end
    results_with_index.sort {|a,b| b[1] <=> a[1]}.first(3).each do |entry|
      document, score = entry
      document = num_to_doc(document)
      if score > 0
        puts "#{document} #{score}" 
        print_document(document)
      end
    end
  end

  def print_document(document)
    contents = File.read(document)
    middle = (contents.length)/2
    beg, en = middle-50, middle+50
    puts "... " + contents[beg..en] + " ..."
  end

private
  def doc_to_num(s)
    s.scan(/\d\d/).first.to_i-1
  end

  def num_to_doc(n)
    "./test2/file%02d.txt" % (n+1)
  end

  def word_to_num(s)
    RubyProf.start
    words_hash[s]
    result = RubyProf.stop

    # Print a flat profile to text
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, 0)
    die "end"
  end

  def num_to_word(n)
    words_hash.invert[n]
  end

  # When we add an entry to a wordlist, we want to know
  # 1. The word itself
  # 2. What document it came from
  # 3. Where in that document is the word located
  def add(word, document, location)
    @word_list[word] = Hash.new if @word_list[word].nil?
    @word_list[word][document] = Array.new if @word_list[word][document].nil?
    @word_list[word][document] << location
  end
  
  # Let's not include empty, null, or words in the stop list
  def word_does_not_belong(word)
    word.nil? || word.empty? || @stop_list.index(word)
  end
  
  # document frequency: the number of documents in the collection in which the term occurs
  def df(t)
    @word_list[t].size
  end
  
  # inverse document frequency: idf is a measure of the informativeness of the term.
  # We use [log(N/dft)] instead of [N/dft] to “dampen” the
  # effect of idf.
  def idf(t)
    Math.log10(@documents.size.to_f/df(t).to_f)
  end
  
  # term frequency: number of times that t occurs in d
  def tf(t, d)
    begin
      raise "wordlist doesn't contain #{t}" if @word_list[t].nil?
      raise "#{t} doesn't appear in #{d}" if @word_list[t][d].nil?
      @word_list[t][d].size
    rescue Exception => e
      raise "Error in tf: #{t}, #{d} #{e}\n"
    end
  end
  
  # log frequency weight: The log frequency weight of term t in d
  def w(t, d)
    tf(t, d) > 0 ? 1 + Math.log10(tf(t, d)) : 0
  end
  
  # The tf.idf weight of a term is the product of its 
  # tf weight and its idf weight.
  def tfidf(t, d)
    w(t, d) * idf(t)
  end
  
  # given a document and a location, give me some 
  # characters before and after that location
  def get_word_in_context(d, loc)
    before = 20
    after = 20
    "\t... #{d[(loc-before < 0 ? 0 : loc-before)..(loc+after > d.size ? d.size : loc+after)]} ..."
  end
  
  # given a set of words, we find all documents that have all these words
  def find_documents_with_all_words(words)
    # Just get the names of all possible documents
    documents = @documents.keys
    # Now for each word passed in
    words.each do |word|
      # We do a repeated setwise intersection
      documents = documents & @word_list[word].keys unless @word_list[word].nil? || @word_list[word].empty?
    end
    # Now we have all the documents that all the words are in.
    # And we transform that into a Hashtable where the keys are the
    # names of those documents and the values are initialized to zero.
    documents.inject(Hash.new) {|a,b| a.merge({b,0})}
  end
end

class String
  # Here we're adding a special new method to the String
  # class that allows us to split on a separator, giving us
  # tokens, but we also get the index of that token in the form
  # [token, index]
  def split_with_index(sep)
    ret = Array.new
    current = ["", 0]
    index = 0
    while index < self.size
      if self[index].chr == sep
        ret << current
        current = ["", index + 1]
      else
        current[0] << self[index]
      end
      index += 1
    end
    ret << current
    ret
  end
  
  def stem!
    self.gsub!(/[\W]+/, '') # strip garbage
    self.downcase! unless self.nil? # downcase if there's anything left
  end
end