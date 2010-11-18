require "test/unit"
require "pp"
require "svd-engine"
require "search_engine"
require "linalg"

def find_top_three(arr)
  [1, 2, 3]
end

class TestSvdEngine < Test::Unit::TestCase
  def test_homework_part_1
    engine = SVDEngine.new('usersong.txt', 3)
    # Part A
    pp engine.c.singular_values
    
    # Part B
    puts ((engine.ck - engine.c)*100).to_s(format = "% 10.0f")
    
    # Part D
    newuser1 = Linalg::DMatrix[[6, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
    newuser2 = Linalg::DMatrix[[0, 0, 0, 0, 0, 2, 0, 0, 0, 4]]
    newuser3 = Linalg::DMatrix[[0, 3, 0, 0, 0, 0, 0, 3, 0, 0]]
    newuser4 = Linalg::DMatrix[[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]
    puts
    puts newuser1.to_s(format = "% 10.2f")
    puts engine.recommendations(newuser1).to_s(format = "% 10.2f")
    puts newuser2.to_s(format = "% 10.2f")
    puts engine.recommendations(newuser2).to_s(format = "% 10.2f")
    puts newuser3.to_s(format = "% 10.2f")
    puts engine.recommendations(newuser3).to_s(format = "% 10.2f")
    puts newuser4.to_s(format = "% 10.2f")
    puts engine.recommendations(newuser4).to_s(format = "% 10.2f")
  end
  
  def test_term_doc_matrix
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    m =  Linalg::DMatrix.rows search_engine.term_document_matrix
    words = search_engine.words_hash
    u, s, vt = m.singular_value_decomposition
    puts "u:"
    pp u.dimensions
    puts "s:"
    pp s
    puts "vt:"
    pp vt.dimensions
  end
  
  def test_first_n_words
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.print_word_list(100, 200)
  end
  
  def test_create_query_vector
    search_engine = SearchEngine.new('./test2/file*','stoplist.txt')
    c = Linalg::DMatrix.rows search_engine.term_document_matrix
    q = Linalg::DMatrix[search_engine.query_vector("marcell")]
    results = (q * c).to_a[0]
    results_with_index = []
    results.each_with_index do |item, idx|
      results_with_index << [idx, item]
    end
    results_with_index.sort {|a,b| b[1] <=> a[1]}.first(3).each do |entry|
      document, score = entry
      puts "#{document} #{score}" if score > 0
    end
  end
  
  def test_test_query
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.query("zuckerberg")
  end
  
  def test_find_top_three
    assert_equal([3, 6, 2], find_top_three([0, 1, 5, 7, 1, 3, 6, 4]))
  end
  
  def test_print_some_of_document
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.print_document('./test/file01.txt')
  end
end