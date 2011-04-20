require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module KinkitSpecH
  GraphEdges = [ [:aa, :a], [:bc, :bbb], [:bc,:b], [:aaa, :aa], [:b, nil], [:ba,:b],
                 [:ba, :ab], [:ac, :a], [:bbb, :bb], [:bbb, :aaa], [:a, :aa],
                 [:ab, :a], [:ab, :aaa], [:ab, :bb], [:bcc, :bc], [:bb, :b],
                 #this edge is not connected
                 [:cc, :c] ]

end


describe "Kinkit" do
  it "fails" do
    fail "hey buddy, you should probably rename this file and start specing for real"
  end
end
