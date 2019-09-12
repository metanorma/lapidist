RSpec.describe Lapidist do
  it "has a version number" do
    expect(Lapidist::VERSION).not_to be nil
  end

  it "gems not empty for valid path" do
    expect(Lapidist::gems('../')).to match_array []
  end
end
