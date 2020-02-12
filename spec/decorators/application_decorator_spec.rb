require "rails_helper"

RSpec.describe ApplicationDecorator, type: :decorator do
  describe "#object" do
    it "exposes the decorated object" do
      obj = Class.new
      expect(described_class.new(obj).object).to be(obj)
    end
  end

  # as ApplicationDecorator is an abstract class, some tests also use an actual decorator
  describe ".decoratecollection" do
    before do
      create(:sponsorship, level: :gold)
    end

    it "receives an ActiveRecord relation and returns an array of decorated records" do
      relation = Sponsorship.gold

      decorated_collection = described_class.decoratecollection(relation)
      expect(decorated_collection.map(&:class)).to eq([SponsorshipDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end

    it "receives an array and returns an array of decorated records" do
      relation = Sponsorship.gold

      decorated_collection = described_class.decoratecollection(relation.to_a)
      expect(decorated_collection.map(&:class)).to eq([SponsorshipDecorator])
      expect(decorated_collection.map(&:object)).to eq(relation.to_a)
    end
  end
end
