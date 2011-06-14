require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module KinkitSpecH
    #TODO: Add parents and complex relationships
    BurpRelations  = {
      :a => {:id => :a, :parents => [:aa], :data => "A", :other_stuff => "_A_"},
      #b,c have no parents
      :b => {:id => :b, :data => "B", :other_stuff => "_B_"},
      :c => {:id => :c, :data => "C", :other_stuff => "_C_"},
      :aa => {:id => :aa, :parents => [:a], :data => "AA", :other_stuff => "_AA_"},
      :ab => {:id => :ab, :parents => [:a, :bb, :aaa], :data => "AB", :other_stuff => "_AB_"},
      :ac => {:id => :ac, :parents => [:a], :data => "AC", :other_stuff => "_AC_"},
      :ba => {:id => :ba, :parents => [:b, :ab], :data => "BA", :other_stuff => "_BA_"},
      :bb => {:id => :bb, :parents => [:b], :data => "BB", :other_stuff => "_BB_"},
      :bc => {:id => :bc, :parents => [:b, :bbb], :data => "BC", :other_stuff => "_BC_"},
      :cc => {:id => :cc, :parents => [:c], :data => "CC", :other_stuff => "_CC_"},
      :aaa => {:id => :aaa, :parents => [:aa], :data => "AAA", :other_stuff => "_AAA_"},
      :bbb => {:id => :bbb, :parents => [:bb, :aaa], :data => "BBB", :other_stuff => "_BBB_"},
      :bcc => {:id => :bcc, :parents => [:bc], :data => "BCC", :other_stuff => "_BCC_"},
      #d has no children and no parents (orphan node)
      :d => {:data => "DDD", :other_stuff => "_DDD_"}
    }

   ParentID = :parents
   UniqGraph1 = RGL::DirectedAdjacencyGraph[[:a, :aa], [:a, :ab], [:a, :ac],
                                          [:aa, :a], [:aa, :aaa], [:aaa, :ab], [:aaa, :bbb], [:ab, :ba],
                                          [:b, :ba], [:b, :bb], [:b, :bc],
                                          [:bb, :bbb], [:bb, :ab], [:bc, :bcc], [:bbb, :bc]]

   UniqGraph2 = RGL::DirectedAdjacencyGraph[[:c, :cc]]

   BurpingChildren = {:a => {:children => [:aa, :ab, :ac]},
                      :b => {:children => [:ba, :bb, :bc]},
                      :c => {:children => [:cc]},
                      :aa => {:children => [:a, :aaa]},
                      :ab => {:children => [:ba]},
                      :ac => {:children => []},  
                      :ba => {:children => []},
                      :bb => {:children => [:ab, :bbb]},
                      :bc => {:children => [:bcc]},
                      :cc => {:children => []},
                      :aaa => {:children => [:ab, :bbb]},
                      :bbb => {:children => [:bc]},
                      :bcc => {:children => []}
   }
   
   Orphans = [:d]

end


describe "Kinkit" do
  include KinkitSpecH

  before(:each) do
    @burp_nodes = BurpRelations
    @parent_id = ParentID
    @uniq_graph1 = UniqGraph1
    @uniq_graph2 = UniqGraph2
    @orphans = Orphans
    @nodes_with_children = BurpRelations.merge(BurpingChildren){|k,v1,v2| v1.merge(v2)}
  end

  it "initializes correctly" do
    bug = Kinkit.new(@burp_nodes, @parent_id)
    bug.should be_a Kinkit
    bug.uniq_digraphs.should == [@uniq_graph2, @uniq_graph1]
    bug.parent_child_maps.each do |node, node_data|
      node_data.each do |data_key, data|
        if ( data && data.is_a?(Array) && @nodes_with_children[node][data_key] )
          data.sort.should == @nodes_with_children[node][data_key].sort
        elsif @nodes_with_children[node][data_key].nil?
          data.should == []
        else
          data.should == @nodes_with_children[node][data_key]
        end
      end
    end
    bug.orphans.should == @orphans
  end
end
