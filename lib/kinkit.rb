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
end
