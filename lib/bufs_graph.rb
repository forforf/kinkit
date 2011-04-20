require 'rgl/adjacency'
require 'rgl/traversal'
require 'json'

class MyDG < RGL::DirectedAdjacencyGraph
  
  #Graphs with identical edges should respond
  #as identical to methods such as #==
  def hash
    a = self.edge_array.sort
    h = a.hash
  end
  
  #Graphs with identical edges should respond
  #as identical to methods such as #==
  def eql?(other)
    self.edge_array.sort == other.edge_array.sort
  end

  #A rough hack to get the in-degree for a vertex
  #There's probably a better way than #reverse
  #but I lack the chops for it
  def in_degree(v)
    rdg = self.reverse
    rdg.adjacent_vertices(v).size
  end

  def out_degree(v)
    self.adjacent_vertices(v).size
  end
  
  #Find nodes with #in_degree of 0
  def nodes_with_no_parents
    top_nodes = []
    self.each_vertex do |v|
      if in_degree(v) == 0
        top_nodes << v
      end
    end
    top_nodes
  end
  
  #selects the node(s) with the maximum #out_degree
  #this can probably be optimized 
  #or at least refactored for greater clarity 
  def best_top_nodes
    top_nodes = {}
    self.each_vertex do |v|
      top_nodes[v] = self.bfs_search_tree_from(v).size
    end
    max = top_nodes.values.max
    top_verts = top_nodes.select{|k,v| v == max}.keys
  end

  #returnes edges as a nested array
  # [ [from, to], [from, to] ... ]
  def edge_array
    self.edges.map{|edge| edge.to_a}
  end
  
  #find parents to a given vertex
  def source_vertices(v)
    rdg = self.reverse
    rdg.adjacent_vertices(v)
  end
  
  #determines if current digraph overlaps
  #with another digraph (i.e. any shared vertices)
  def connected_to?(dg)
    self_verts = self.vertices
    dg_verts = dg.vertices
    connected = if (self_verts & dg_verts).empty?
        false
    else
      true
    end
    connected
  end
  
  #merge with another digraph
  def merge(other)
    self.add_edges(*other.edge_array)
    self
  end
  
  #returns false if no connected edges, otherwise returns
  #the edges that connects
  #shoulr probably return nil if no edges connect
  def connected_edges?(this_edges, other_edges)
    intersection = this_edges.flatten & other_edges.flatten
    if intersection.nil? || intersection.empty? 
      false
    else
      this_edges | other_edges
    end
  end
  
  #This breaks the graph down and returns an array of 
  #its component digraphs, where each edge forms a single digraph
  #(i.e., an array of digraphs, each with two vertices)
  def atomic_graphs
    edges = self.edge_array
    uniq_dgs = edges.map {|edge| MyDG[*edge] }
    uniq_dgs
  end
 
  #Takes a list of digraphs and determines if they have any overlap
  #and combines any overlapped digraphs into a common digraph 
  def find_connected_graphs(dgs=self.atomic_graphs)
    #dg = directed graph
    merged_dgs = Marshal.load(Marshal.dump(dgs))
    uniq_dgs = []
    
    until  merged_dgs.empty? do

      eval_dg = merged_dgs.shift
      uniq = true
      
      #check and see if the dg under eval should be merged into 
      #one of the other dgs
      merged_dgs.each do |other_dg| #merge loop

        if eval_dg.connected_to? other_dg
          uniq = false
          other_dg.merge(eval_dg)
          #eval_dg is now part of an existing dg in the merged_dgs array
          
          #we are now merged, and the new merged dg will be checked against the
          #remaining dgs, so there's no reason to continue the loop
          break #exit merge loop
        end
      end
      
      
      if uniq == true #means we went through the entire array without a match
        uniq_uniq = true
        #see if it merges with any thing in the uniq list so far
        uniq_dgs.each do |u_dg|
          if eval_dg.connected_to? u_dg
            uniq_uniq = false
            u_dg.merge(eval_dg)
          end
        end
        uniq_dgs << eval_dg if uniq_uniq
      end
    end
    uniq_dgs.uniq
  end
end
  
class BuildBugs 
  
  attr_accessor :uniq_digraphs, :parent_child_maps, :pc_combined_map
  def initialize(burped_map, parent_label)
    nodes_map = burped_map
    @nodes_map = nodes_map
    @parents_key =parent_label || :parents
    pp @nodes_map
    p @nodes_map.size
    just_essentials = bare_bones(@nodes_map, @parents_key)
    child_parent_rgl = format_for_rgl(just_essentials, @parents_key)
    child_parent_dg = MyDG[*child_parent_rgl]
    parent_child_rgl = child_parent_dg.reverse.edges.map{|e| e.to_a}.flatten
    parent_child_dg = MyDG[*parent_child_rgl]
    @uniq_digraphs = parent_child_dg.find_connected_graphs
    @parent_child_maps = map_parent_and_children(parent_child_dg, child_parent_dg, @nodes_map)
  end


  def map_parent_and_children(parent_dg, children_dg, nodes_map)
    full_map = {}
    parent_dg.each_vertex do |vert|
      #not all parents exist
      if nodes_map[vert]
        #if they do
        full_map[vert] = nodes_map[vert].merge({:children => parent_dg.adjacent_vertices(vert)})
      else
        #if they don't create a stub node
        full_map[vert] = {:parents => nil, :children => parent_dg.adjacent_vertices(vert)}
      end
    end
    full_map
  end

    
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

  def bare_bones(node_map, parents_key)
    node_map.merge(node_map){|k, old_v, new_v| {parents_key => new_v[parents_key]} }
  end
  
  def parent_child_rgl(child_parent_list)
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
  
  def list_to_map(list, node_structure)
    id = node_structure[:id] || :id
    new_map = {}
    list.each do |n|
      new_map[n[id]] = n.reject{|key, val| key == id}
    end
    new_map
  end
  
  def parent_child_builder(orig_node_list, uniq_digraphs, structure)
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
