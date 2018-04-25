RSpec.describe ElasticSearchFramework::Repository do
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
  let(:item5) do
    {
        id: 5,
        name: 'peter',
        timestamp: Time.now.to_i + 400,
        number: 25
    }
  end

  describe '#get' do
    before do
      ExampleIndex.delete
      ExampleIndex.create
    end
    context 'when no index document exists' do
      it 'should return nil' do
        expect(subject.get(index: ExampleIndex, id: item1.id)).to eq nil
      end
    end
    after do
      ExampleIndex.delete
    end
  end

  describe '#CRUD' do
    before do
      ElasticSearchFramework.namespace = 'test'
      ElasticSearchFramework.namespace_delimiter = '_'
      ExampleIndexWithId.delete
      ExampleIndexWithId.create
    end

    it 'should create, read and delete an index document' do
      subject.set(index: ExampleIndex, entity: item1)
      subject.set(index: ExampleIndex, entity: item2)
      subject.set(index: ExampleIndex, entity: item5)
      index_item1 = subject.get(index: ExampleIndex, id: item1.id)
      expect(index_item1[:id]).to eq item1.id
      expect(index_item1[:name]).to eq item1.name
      expect(index_item1[:timestamp]).to eq item1.timestamp
      expect(index_item1[:number]).to eq item1.number
      index_item2 = subject.get(index: ExampleIndex, id: item2.id)
      expect(index_item2[:id]).to eq item2.id
      expect(index_item2[:name]).to eq item2.name
      expect(index_item2[:timestamp]).to eq item2.timestamp
      expect(index_item2[:number]).to eq item2.number
      subject.drop(index: ExampleIndex, id: item1.id)
      expect(subject.get(index: ExampleIndex, id: item1.id)).to be_nil
    end

    after do
      ExampleIndexWithId.delete
    end
  end

  describe '#query' do
    before do
      ExampleIndex.delete
      ExampleIndex.create

      subject.set(index: ExampleIndex, entity: item1)
      subject.set(index: ExampleIndex, entity: item2)
      subject.set(index: ExampleIndex, entity: item3)
      subject.set(index: ExampleIndex, entity: item4)
      sleep 1
    end

    it 'should return the expected query results' do
      results = subject.query(index: ExampleIndex, expression: 'name:"fred"')
      expect(results.length).to eq 1
      expect(results[0][:_source][:name]).to eq item1.name
      expect(results[0][:_source][:id]).to eq item1.id
      expect(results[0][:_source][:timestamp]).to eq item1.timestamp
      expect(results[0][:_source][:number]).to eq item1.number

      results = subject.query(index: ExampleIndex, expression: 'number:>5')
      expect(results.length).to eq 3

      results = subject.query(index: ExampleIndex, expression: 'number:>=15')
      expect(results.length).to eq 2

      results = subject.query(index: ExampleIndex, expression: 'NOT (name:john)')
      expect(results.length).to eq 3
    end

    after do
      ExampleIndex.delete
    end
  end

  describe '#host' do
    it 'should return the expected host based on default host & port values' do
      expect(subject.host).to eq "#{ElasticSearchFramework.host}:#{ElasticSearchFramework.port}"
    end
  end

end
