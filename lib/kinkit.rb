require 'rgl/adjacency'

class Kinkit
  MyDG = RGL::DirectedAdjacencyGraph
  
  attr_accessor :uniq_digraphs, :parent_child_maps

  def initialize(burped_map, parent_label)
    @nodes_map = burped_map
    @parents_key =parent_label || :parents
    just_essentials = bare_bones(@nodes_map, @parents_key)
    child_parent_rgl = format_for_rgl(just_essentials, @parents_key)
    child_parent_dg = MyDG[*child_parent_rgl]
    parent_child_rgl = child_parent_dg.reverse.edges.map{|e| e.to_a}.flatten
    parent_child_dg = MyDG[*parent_child_rgl]
    @uniq_digraphs = parent_child_dg.find_connected_graphs
    @parent_child_maps = map_parent_and_children(parent_child_dg, child_parent_dg, @nodes_map)
  end

  #make private?
  def map_parent_and_children(parent_dg, children_dg, nodes_map)
    full_map = {}
    parent_dg.each_vertex do |vert|
      #not all parents exist
      if nodes_map[vert]
        #if they do
        full_map[vert] = nodes_map[vert].merge({:children => parent_dg.adjacent_vertices(vert)})
      else
        #if they don't create a stub node
        full_map[vert] = {:parents => [], :children => parent_dg.adjacent_vertices(vert)}
      end
    end
    full_map
  end

  #make private?
  def format_for_rgl(node_map, parents_key)
    bug_rgl = []
    node_map.each do |id, data|
      parents = data[parents_key] 
      parents = [] unless parents
      parents = [parents].flatten unless parents.respond_to? :each
      parents.each do |parent|
        bug_rgl += [id, parent]
      end
    end
    bug_rgl
  end

  #make private?
  def bare_bones(node_map, parents_key)
    node_map.merge(node_map){|k, old_v, new_v| {parents_key => new_v[parents_key]} }
  end
  

  #not used? Never called?
  def parent_child_rgl(child_parent_list)
    raise "Who is calling me"
    rgl_list = []
    child_parent_list.each do |node|
      edges = []
      if node[:parents]
        parents = node[:parents].compact
      else
        #p node
        next
      end
      parents.each do |parent|
        edges << [parent, node[:id]]
      end
      rgl_list += edges
    end 
    rgl_list
  end
  
  #Delete? Seems related to orphaned method
  def list_to_map(list, node_structure)
    raise "Who is calling me?"
    id = node_structure[:id] || :id
    new_map = {}
    list.each do |n|
      new_map[n[id]] = n.reject{|key, val| key == id}
    end
    new_map
  end
 
  #never called? 
  def parent_child_builder(orig_node_list, uniq_digraphs, structure)
    raise "Who is calling me?"
    #Note that sometimes the parent may not exist as a real node
    #In those cases a rudimentary node is created for that parent (in order to hold the children)
    #Because the tree is built from the children, all children exist as defined nodes
    #Children are assigned to the key :children 
    id = structure[:id] || :id
    parents =structure[:parents_label] || :parents
    orig_node_list_by_id = list_to_map(orig_node_list, structure)
    parent_child_lists = []
    #invert the digraphs
    uniq_digraphs.each do |dg|
      parent_child_list = []
      dg.each do
        rev_dg = dg.reverse
        rev_dg.each_vertex do |vert|
          children = dg.adjacent_vertices(vert)
          if orig_node_list_by_id[vert]
            #parent exists as a defined node
            parent_child_list  << orig_node_list_by_id[vert].merge({id => vert, :children => children})
          else
            #parent was a label, not a physical node, so we have to create a rudimentary node
            parent_child_list << {id => vert, :children => children}
          end
        end
      end
      parent_child_lists << parent_child_list.uniq
    end
    parent_child_lists
  end
end
