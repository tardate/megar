# Collection manager for files
class Megar::Files
  include Megar::CatalogItem

  def initialize(options={})
  end

  # Adds an item to the local cached collection given +attributes+ hash.
  def add(attributes)
    collection << Megar::File.new(attributes)
  end

end