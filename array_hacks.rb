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