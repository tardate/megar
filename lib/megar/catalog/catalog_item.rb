# This module defines the basic naming interface for catalog objects
# Override these methods as required
module Megar::CatalogItem
  include Enumerable

  # Adds an item to the local cached collection given +attributes+ hash:
  #   id:         id / mega node handle
  #   payload:    the literal mega node descriptor
  #   type:       the folder type
  #   key:        the decrypted folder key
  #   attributes: the decrypted attributes collection
  def initialize(attributes={})
    self.attributes = attributes
  end

  # The ID (Mega handle)
  attr_accessor :id

  # The folder name
  attr_accessor :name
  alias_method :n=, :name=

  # The literal mega node descriptor (as received from API)
  attr_accessor :payload

  # Assigns the payload attribute, also splitting out separate attribute assignments from +value+ if a hash
  def payload=(value)
    self.attributes = value
    @payload = value
  end

  # Assigns the attribute values splitting out separate attribute assignments from +value+ if a hash
  def attributes=(value)
    return unless value.respond_to?(:keys)
    value.keys.each do |key|
      if respond_to?(assignment = "#{key}=".to_sym)
        send(assignment,value[key])
      end
    end
  end

  # The decrypted node key
  attr_accessor :key

  # The folder type id
  #   0: File
  #   1: Directory
  #   2: Special node: Root (“Cloud Drive”)
  #   3: Special node: Inbox
  #   4: Special node: Trash Bin
  attr_accessor :type


  # Generic interface to return the currently applicable collection
  def collection
    @collection ||= []
  end

  # Returns the expected class of items in the collection
  def resource_class
    "#{self.class.name}".chomp('s').constantize
  end

  # Command: clears/re-initialises the collection
  def reset!
    @collection = []
  end

  # Implements Enumerable#each
  def each
    collection.each { |item| yield item }
  end

  # Returns indexed elements from the collection
  def [](*args)
    collection[*args]
  end

  # Equality based on ID
  def ==(other)
    self.id == other.id
  end
  alias_method :eql?, :==

  # Returns the first record matching +type+
  def find_by_type(type)
    find { |r| r.type == type }
  end

end
