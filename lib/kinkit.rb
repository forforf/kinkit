#TODO move away from forforf-rgl
# and just inlcude the forforf specific modules

require 'rgl/adjacency'
require 'rgl/implicit'
require 'rgl/mutable'
require 'rgl/traversal'

module GraphIntersection
=begin
  def alias_nils(nil_term = :zzznull)
    edges = self.edge_array
    return self unless edges.flatten.include? nil
    fixed_edges = edges.map{ |edge| edge.map{ |v| v || nil_term } }
    #WARNING returns a new, different object though it should be #eql?
    #to the original
    #unimplemented methods in core class prevent me 
    #from changing self itself (add/remove vertex)
    fixed_dg = self.class[*fixed_edges.flatten]
  end

  #Graph identity is based on edges
  def hash
    a = self.alias_nils.edge_array
    h = a.hash
  end
 
  #Graphs are #eql? if edges are equal
  #TODO update the other equality methods
  def eql?(other)
    self.hash == other.hash
  end

  #A rough hack to get the in-degree for a vertex
  #nil vertices are not counted (TODO Prevent nil verts in RGL)
  #There's probably a better way than #reverse
  #but I lack the chops for it
  def in_degree(v)
    rdg = self.reverse
    rdg.out_degree(v)
  end

  #  out_degree is already defined in base class
  #def out_degree(v)
  #  self.adjacent_vertices(v).size
  #end
  
  #Find nodes with #in_degree of 0
  #Although roots isn't strictly a digraph term (it's for trees)
  #it has the right connotation
  def roots
    top_nodes = []
    self.each_vertex do |v|
      if in_degree(v) == 0
        top_nodes << v
      end
    end
    top_nodes
  end
  #deprecated method name
  alias :nodes_with_no_parents :roots

=end
  #selects the vertices with the maximum tree size (not just out degree)
  def best_top_vertices
    top_nodes = {}
    self.each_vertex do |v|
      top_nodes[v] = self.bfs_search_tree_from(v).size
    end
    max = top_nodes.values.max
    top_verts = top_nodes.select{|k,v| v == max}.keys
  end
  #deprecated method name
  alias :best_top_nodes :best_top_vertices

=begin
    def add_edge (u, v)
      raise NotImplementedError
    end

    # Add all objects in _a_ to the vertex set.

    def add_vertices (*a)
      a.each { |v| add_vertex v }
    end
=end


  #returnes edges as a nested array
  # [ [from, to], [from, to] ... ]
  def edge_array
    self.edges.map{|edge| edge.to_a}
  end
=begin  
  #find parents to a given vertex
  def source_vertices(v)
    rdg = self.reverse
    rdg.adjacent_vertices(v)
  end
=end
  #determines if current digraph overlaps
  #with another digraph (i.e. any shared vertices)
  def connected_to?(dg)
    self_verts = self.vertices
    dg_verts = dg.vertices
    #puts "Self Vs: #{self_verts.inspect}"
    #puts "DG Vs: #{dg_verts}"
    connected = if (self_verts & dg_verts).empty?
        false
    else
      true
    end
    #puts "Connected: #{connected}"
    connected
  end

  #merge with another digraph
  def merge(other)
    self.add_edges(*other.edge_array)
    self
  end
=begin  
  #test for edges that connect, note: returns union of the edges.
  def connected_edges?(this_edges, other_edges)
    intersection = this_edges.flatten & other_edges.flatten
    if intersection.nil? || intersection.empty? 
      nil
    else
      res = this_edges | other_edges
    end
  end
=end  
  #This breaks the graph down and returns an array of 
  #its component digraphs, where each edge forms a single digraph
  #(i.e., an array of digraphs, each with two vertices)
  def atomic_graphs
    edges = self.edge_array
    uniq_dgs = edges.map do |edge|
      a_dg = RGL::DirectedAdjacencyGraph[*edge]
      a_dg.extend(GraphIntersection)
      a_dg
    end
    uniq_dgs
  end
 
  #Takes a list of digraphs and determines if they have any overlap
  #and combines any overlapped digraphs into a common digraph 
  #returns a list of dgs that are unconnected to each other
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

      puts "Looked at other dgs, Uniq is now: #{uniq}"
      
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
#TODO: move to different file
#creates an inverse parent-child graph (children nodes have parent subnodes)
class Grapher
  attr_accessor :child_parent_graph, :parent_child_graph
  
  
  def initialize(child_parent_map)
    cp_verts = child_parent_map.keys

    @child_parent_graph = RGL::ImplicitGraph.new {|g|  
      g.vertex_iterator { |b| cp_verts.each(&b) }
      g.adjacent_iterator { |x, b|
        parents = child_parent_map[x][:parents] || []
        parents.each { |y| b.call(y) }
      }
      g.directed = true
    }
    
    @parent_child_graph = @child_parent_graph.reverse
    @parent_child_graph.extend(GraphIntersection)
  end
end

class Kinkit
  attr_accessor :uniq_digraphs, :parent_child_maps, :orphans

  def initialize(burped_map, parent_label)
    @nodes_map = burped_map
    @parents_key =parent_label || :parents
    just_essentials = bare_bones(@nodes_map, @parents_key)
    
    grapher = Grapher.new(just_essentials)
    child_parent_dg = grapher.child_parent_graph
    parent_child_dg = grapher.parent_child_graph
    @uniq_digraphs = parent_child_dg.find_connected_graphs
    uniq_verts = @uniq_digraphs.inject([]){|m,g| m<<g.vertices}.flatten
    #orphans have no parents or children
    orphan_keys = just_essentials.keys - uniq_verts
     @nodes_map
    #Not sure this is the best way for dealing with orphans
    #Returns a Digraph of (:orphan -> :orphan)
    #This is probably a broken way of doing things
    @orphans = []
    orphan_keys.each do |ok|
      orphan = @nodes_map[ok]
      @orphans << RGL::ImplicitGraph.new {|g|
        g.vertex_iterator { |b| [orphan].each(&b) }
        g.adjacent_iterator {|x, b| [orphan].each {|y| b.call(y) }}
        g.directed = true
      }
    end
    #p @orphans  
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
  def bare_bones(node_map, parents_key)
    node_map.merge(node_map){|k, old_v, new_v| {parents_key => new_v[parents_key]} }
  end
end
