require "rock_pod"

describe RockPod do

  describe "::TrackGroups" do
    let(:groups) {
      h = { "foo" => /foo/, "bar" => /bar/ }
      h.extend RockPod::TrackGroups
      h
    }
    let(:tracks) { %w(foo/x fooz/y bar/z baz/a) }
    let(:groupped) { groups.group_tracks tracks }

    describe "#group_tracks" do
      it "places each file in its group" do
        expect( groupped["foo"] ).to match_array %w(foo/x fooz/y)
        expect( groupped["bar"] ).to match_array %w(bar/z)
      end

      it "places unknown files into misc" do
        expect( groupped["misc"] ).to match_array %w(baz/a)
      end
    end

  end

end
