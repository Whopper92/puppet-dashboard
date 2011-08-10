class NodeClass < ActiveRecord::Base
  def self.per_page; 50 end # Pagination

  include NodeGroupGraph

  has_many :node_group_class_memberships, :dependent => :destroy
  has_many :node_class_memberships, :dependent => :destroy

  has_many :node_group_children, :class_name => "NodeGroup", :through => :node_group_class_memberships, :source => :node_group
  has_many :nodes, :through => :node_class_memberships

  validates_presence_of :name

  validates_format_of :name, :with => /\A([a-z0-9][-\w]*)(::[a-z0-9][-\w]*)*\Z/, :message => "must contain a valid Puppet class name, e.g. 'foo' or 'foo::bar'"
  validates_uniqueness_of :name

  default_scope :order => 'name ASC'

  named_scope :search, lambda{|q| q.blank? ? {} : {:conditions => ['name LIKE ?', "%#{q}%"]} }

  named_scope :with_nodes_count,
    :select => 'node_classes.*, count(nodes.id) as nodes_count',
    :joins => 'LEFT OUTER JOIN node_class_memberships ON (node_classes.id = node_class_memberships.node_class_id) LEFT OUTER JOIN nodes ON (nodes.id = node_class_memberships.node_id)',
    :group => 'node_classes.id'

  def to_json(options)
    super({:methods => :description, :only => [:name, :id]}.merge(options))
  end

  def self.find_from_form_names(*names)
    names.reject(&:blank?).map{|name| self.find_by_name(name)}.uniq
  end

  def self.find_from_form_ids(*ids)
    ids.map{|entry| entry.to_s.split(/[ ,]/)}.flatten.reject(&:blank?).uniq.map{|id| self.find(id)}
  end

  def <=>(rhs)
    self.name <=> rhs.name
  end
end
