require 'linalg'

class SVDEngine
  attr_reader :c, :u, :s, :vt, :ck

  def initialize(datafile, k)
    # k is the number of singular values to keep
    @k = k
    # read the file into matrix C
    @c = File.read(datafile)
    @c = Linalg::DMatrix.rows @c.split("\n").map {|x| x.split.map {|y| y.to_i}}
    # Perform singular value decomposition
    @u, @s, @vt = @c.singular_value_decomposition
    # Get rid of all but k singular values
    (k...@s.dimensions.min).each do |x|
      @s[x,x] = 0
    end
    # compute our new Ck
    @ck = @u * @s * @vt
  end
  
  def recommendations(newuser)
    # To do this, you need to right multiply the vector by V to transform to feature space, 
    temp = newuser * @vt.transpose
    # zero out the entries corresponding to the truncation of Σ
    (@k...@c.dimensions[1]).each {|x| temp[0,x] = 0}
    # transform the result back to user coordinates by right multiplying by VT
    temp * @vt
    # then compare with the initial user vector.
  end
end