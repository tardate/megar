# Folder collection item
class Megar::Folder
  include Megar::CatalogItem

  # Name assignment with special-purpose name support
  def name=(value)
    @name = if "#{value}" != ""
      value
    elsif type.is_a?(Fixnum)
      ["Cloud Drive","Inbox","Trash Bin"][type-2]
    end
  end

  # Override initialisation to set special-purpose names
  def initialize(attributes={})
    super
    self.name = nil unless name
  end

end