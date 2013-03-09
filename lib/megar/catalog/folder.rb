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

  # Command: creates a new file given +attributes+ which contains the following elements:
  #   body: the file body. May be a Pathname, File, or filename (String)
  #   name: the file name to assign (optional if already available from the body object)
  #
  # The file is stored in the parent folder (or root folder by defult)
  def create(attributes)
    if uploader = self.uploader(attributes)
      uploader.post!
    end
  end

  protected

  def uploader(attributes)
    Megar::FileUploader.new(attributes.merge(folder: self))
  end

end