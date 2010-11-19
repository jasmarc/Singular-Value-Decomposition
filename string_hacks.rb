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