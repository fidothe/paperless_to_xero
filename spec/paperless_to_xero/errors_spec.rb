require 'spec_helper'

describe PaperlessToXero::RowError do
  it "should be able to be instantiated with the line number, row contents and error message" do
    PaperlessToXero::RowError.new(1, ["thing", "other thing"], "Bad thing happened").should be_instance_of(PaperlessToXero::RowError)
  end
end