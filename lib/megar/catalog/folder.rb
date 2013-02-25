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

  # Returns a collection of folders contained within this folder
  def folders
    return unless session
    session.folders.find_all_by_parent_folder_id(id)
  end

  # Returns a collection of files contained within this folder
  def files
    return unless session
    session.files.find_all_by_parent_folder_id(id)
  end

end