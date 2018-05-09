class Vertex
  attr_accessor :name, :type, :frequency, :index, :node_id, :state, :label, :parent, :pos_tag

  def initialize(name, type, state, label, parent, pos_tag)
    @name = name.downcase
    @type = type
    @frequency = 0
    @node_id = -1 # to identify if the id has been set or not
    @state = state # they are not negated by default
    
    # for semantic role labelling
    @label = label
    @parent = parent
    @pos_tag = pos_tag
  end
end
