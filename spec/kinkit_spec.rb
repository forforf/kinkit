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
      :bcc => {:id => :bcc, :parents => [:bc], :data => "BCC", :other_stuff => "_BCC_"}
    }

   ParentID = :parents
   UniqGraph1 = RGL::DirectedAdjacencyGraph[[:a, :aa], [:a, :ab], [:a, :ac],
                                          [:aa, :a], [:aa, :aaa], [:aaa, :ab], [:aaa, :bbb], [:ab, :ba],
                                          [:b, :ba], [:b, :bb], [:b, :bc],
                                          [:bb, :bbb], [:bb, :ab], [:bc, :bcc], [:bbb, :bc]]

   UniqGraph2 = RGL::DirectedAdjacencyGraph[[:c, :cc]]

end


describe "Kinkit" do
  include KinkitSpecH

  before(:each) do
    @burp_nodes = BurpRelations
    @parent_id = ParentID
    @uniq_graph1 = UniqGraph1
    @uniq_graph2 = UniqGraph2
  end

  it "initializes correctly" do
    bug = Kinkit.new(@burp_nodes, @parent_id)
    bug.should be_a Kinkit
    bug.uniq_digraphs.should == [@uniq_graph1, @uniq_graph2]
    bug.parent_child_maps.should == :foo
  end
end
