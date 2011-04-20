#=begin
x = [1,2 ,2,3 ,2,4, 4,5, 6,4, 1,6, 3,6, 6,7, 4,1]
bufs = [ [:aa, :a], [:bc, :bbb], [:bc,:b], [:aaa, :aa], [:b, nil], [:ba,:b],
            [:ba, :ab], [:ac, :a], [:bbb, :bb], [:bbb, :aaa], [:a, :aa],
            [:ab, :a], [:ab, :aaa], [:ab, :bb], [:bcc, :bc], [:bb, :b], 
            [:cc, :c] ]
            
#p bufs.flatten
#p MyDG.new(*x)
#p MyDG.new(*bufs.flatten)

node_list = [{:id => :aa,    :label => 'AA', :parents => [:a]},
                  {:id => :bc,   :label => 'BC', :parents => [:bbb, :b]},
                  {:id => :aaa,  :label => 'AAA', :parents => [:aa]},
                  {:id => :b,     :label => 'B'},  #try :parents => nil and :parents => [] as well
                  {:id => :ba, :label => 'BA', :parents => [:b, :ab]},
                  {:id => :ac, :label => 'AC', :parents => [:a]},
                  {:id => :bbb, :label => 'BBB', :parents => [:bb, :aaa]},
                  {:id => :a, :label => 'A', :parents => [:aa]},
                  {:id => :ab, :label => 'AB', :parents => [:a, :aaa, :bb]},
                  {:id => :bcc, :label => 'BCC', :parents => [:bc]},
                  {:id => :bb, :label => 'BB', :parents => [:b]},
                  {:id => :cc, :label => 'CC', :parents => [:c]}]

=begin                  
puts "Burp"
p node_map= Burp.new(node_list, :id)
#require 'benchmark'
#puts Benchmark.realtime{
x = BuildBugs.new(node_map, :parents)
jit_struc = {:id => :id, :name_key => :label, :children => :children}
jit_nodes = x.parent_child_maps
digraph = x.uniq_digraphs.first
jit_bug = JsivtBug.new(digraph, jit_nodes, jit_struc)
jit_tree = jit_bug.dg_to_tree(:aa, 4)
pp jit_tree
pp jit_adj = jit_bug.dg_to_adj
#}
puts
puts
 
puts "Final Answers"
pp xx = x.uniq_digraphs
p xx.size
dg = xx
puts "----"
p jit_adj = x.dg_to_adj
puts jit_adj.to_json
puts "===="
top_node = :aa
depth =4
p jit_tree = x.dg_to_tree(dg, top_node,depth)
puts jit_tree.to_json


udgs = x.uniq_digraphs
dg0 = udgs[0]
p y = dg0.best_top_nodes
p dg0.bfs_search_tree_from(y[0])
p dg0.bfs_search_tree_from(y[1])
=end
