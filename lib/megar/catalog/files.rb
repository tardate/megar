# Collection manager for files
class Megar::Files
  include Megar::CatalogItem

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

  # Returns the default parent folder (default is root)
  def default_parent_folder
    session && session.folders.root
  end

  def uploader(attributes)
    Megar::FileUploader.new(attributes.merge(folder: parent_folder))
  end

end