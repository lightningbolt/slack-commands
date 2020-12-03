class Range

  def to_weighted_array
    midpoint = ((self.max - self.min) / 2).ceil
    size = self.size
    array = []
    self.each_with_index do |int, index|
      num_elements = (index > midpoint) ? size - index : index + 1
      array += Array.new(num_elements, int)
    end
    array
  end

end
