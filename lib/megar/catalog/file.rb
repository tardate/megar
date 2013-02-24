# File collection item
class Megar::File
  include Megar::CatalogItem

  # The file size
  attr_accessor :size
  alias_method :s=, :size=

  # Return a pretty version of the file record
  def to_s
    format("%16d bytes  %-10s  %-60s", size.to_i, id, name)
  end

end