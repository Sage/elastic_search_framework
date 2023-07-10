# frozen_string_literal: true

RSpec.describe ElasticSearchFramework::Query do

  subject do
    ElasticSearchFramework::Query.new(index: ExampleIndex)
  end

  describe '#build' do
    it 'should build the expected query string' do
      subject.name.eq('fred').and.age.gt(18).and.gender.not_eq('male')
      expect(subject.build).to eq 'name:fred AND age:>18 AND NOT (gender:male)'
    end
  end

  let(:item1) do
    TestItem.new.tap do |i|
      i.id = 1
      i.name = 'fred'
      i.timestamp = Time.now.to_i
      i.number = 5
    end
  end
  let(:item2) do
    TestItem.new.tap do |i|
      i.id = 2
      i.name = 'john'
      i.timestamp = Time.now.to_i - 100
      i.number = 10
    end
  end
  let(:item3) do
    TestItem.new.tap do |i|
      i.id = 3
      i.name = 'mark'
      i.timestamp = Time.now.to_i - 200
      i.number = 15
    end
  end
  let(:item4) do
    TestItem.new.tap do |i|
      i.id = 4
      i.name = 'paul'
      i.timestamp = Time.now.to_i + 300
      i.number = 20
    end
  end

  describe '#execute' do
    before do
      ExampleIndex.delete
      ExampleIndex.create

      ExampleIndex.put_item(item: item1)
      ExampleIndex.put_item(item: item2)
      ExampleIndex.put_item(item: item3)
      ExampleIndex.put_item(item: item4)
      sleep 1
    end

    it 'should return the expected query results' do
      results = ExampleIndex.query.name.eq('fred').execute
      expect(results.length).to eq 1
      expect(results[0][:_source][:name]).to eq item1.name
      expect(results[0][:_source][:id]).to eq item1.id
      expect(results[0][:_source][:timestamp]).to eq item1.timestamp
      expect(results[0][:_source][:number]).to eq item1.number

      results = ExampleIndex.query.number.gt(5).execute
      expect(results.length).to eq 3

      results = ExampleIndex.query.number.gt_eq(15).execute
      expect(results.length).to eq 2

      results = ExampleIndex.query.number.lt(15).execute
      expect(results.length).to eq 2

      results = ExampleIndex.query.number.lt_eq(15).execute
      expect(results.length).to eq 3

      results = ExampleIndex.query.name.not_eq('john').execute
      expect(results.length).to eq 4

      results = ExampleIndex.query.name.contains?('oh').execute
      expect(results.length).to eq 1
    end

    after do
      ExampleIndex.delete
    end
  end
end
