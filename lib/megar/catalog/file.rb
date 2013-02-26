# File collection item
class Megar::File
  include Megar::CatalogItem

  # Decomposed form the +key+
  attr_accessor :decomposed_key

  # The file size
  attr_accessor :size
  alias_method :s=, :size=

  # Return a pretty version of the file record
  def to_s
    format("%16d bytes  %-10s  %-60s", size.to_i, id, name)
  end

  # Returns the body content of the file
  def body
    downloader.content
  end

  # Returns the a one-shot downloader
  def downloader
    Megar::FileDownloader.new(file: self)
  end

end