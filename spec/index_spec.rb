RSpec.describe ElasticSearchFramework::Index do

  describe '#description' do
    it 'should return the index details' do
      expect(ExampleIndex.description).to be_a(Hash)
      expect(ExampleIndex.description[:name]).to eq 'example_index'
      expect(ExampleIndexWithShard.description[:shards]).to eq 1
    end
  end

  describe '#full_name' do
    let(:namespace) { 'uat' }
    let(:namespace_delimiter) { '.' }
    before do
      ElasticSearchFramework.namespace = namespace
      ElasticSearchFramework.namespace_delimiter = namespace_delimiter
    end
    it 'should return the full index name including namespace and delimiter' do
      expect(ExampleIndex.full_name).to eq "#{ElasticSearchFramework.namespace}#{ElasticSearchFramework.namespace_delimiter}#{ExampleIndex.description[:name]}"
    end
  end

  describe '#mapping' do
    it 'should add mapping details to the index definition' do
      mappings = ExampleIndex.mappings
      expect(mappings).to be_a(Hash)
      expect(mappings.length).to eq 1
      expect(mappings['default'][:name][:type]).to eq :string
      expect(mappings['default'][:name][:analyser]).to eq :not_analyzed
    end
  end

  describe '#valid?' do
    context 'for a valid index definition' do
      it 'should return true' do
        expect(ExampleIndex.valid?).to be true
      end
    end
    context 'for an invalid index definition' do
      it 'should return true' do
        expect(InvalidExampleIndex.valid?).to be false
      end
    end
  end

  describe '#create' do
    before do
      if ExampleIndex.exists?
        ExampleIndex.delete
      end
    end
    it 'should create an index' do
      expect(ExampleIndex.exists?).to be false
      ExampleIndex.create
      expect(ExampleIndex.exists?).to be true
    end
    after do
      ExampleIndex.delete
    end
  end

  describe '#delete' do
    before do
      unless ExampleIndex.exists?
        ExampleIndex.create
      end
    end
    it 'should create an index' do
      expect(ExampleIndex.exists?).to be true
      ExampleIndex.delete
      expect(ExampleIndex.exists?).to be false
    end
  end

  describe '#exists?' do
    context 'when an index exists' do
      before do
        ExampleIndex.delete
        ExampleIndex.create
      end
      it 'should return true' do
        expect(ExampleIndex.exists?).to be true
      end
    end
    context 'when an index exists' do
      before do
        ExampleIndex.delete
      end
      it 'should return false' do
        expect(ExampleIndex.exists?).to be false
      end
    end
  end

  describe '#curl' do
    it 'should return a Curl::Easy instance' do
      expect(ExampleIndex.curl).to be_a(Curl::Easy)
    end
    it 'should return a unique Curl::Easy instance' do
      expect(ExampleIndex.curl).not_to eq ExampleIndex.curl
    end
  end

  describe '#is_valid_response?' do
    let(:client) { double }
    context 'when a 200 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(200)
      end
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(client)).to be true
      end
    end
    context 'when a 201 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(201)
      end
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(client)).to be true
      end
    end
    context 'when a 202 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(202)
      end
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(client)).to be true
      end
    end
    context 'when a 400 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(400)
      end
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(client)).to be false
      end
    end
    context 'when a 401 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(401)
      end
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(client)).to be false
      end
    end
    context 'when a 500 response code is returned' do
      before do
        allow(client).to receive(:response_code).and_return(500)
      end
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(client)).to be false
      end
    end
  end

  describe '#host' do
    it 'should return the expected host based on default host & port values' do
      expect(ExampleIndex.host).to eq "#{ElasticSearchFramework.default_host}:#{ElasticSearchFramework.default_port}"
    end
  end

  describe '#repository' do
    it 'should return a ElasticSearchFramework::Repository instance' do
      expect(ExampleIndex.repository).to be_a(ElasticSearchFramework::Repository)
    end
    it 'should return a unique ElasticSearchFramework::Repository instance' do
      expect(ExampleIndex.repository).not_to eq ExampleIndex.repository
    end
  end

  describe '#get_item' do
    let(:id) { 10 }
    let(:type) { 'default' }
    it 'should call get on the repository' do
      expect_any_instance_of(ElasticSearchFramework::Repository).to receive(:get).with(index: ExampleIndex, id: id, type: type)
      ExampleIndex.get_item(id: id, type: type)
    end
  end

  describe '#put_item' do
    let(:id) { 10 }
    let(:type) { 'default' }
    let(:item) do
      TestItem.new.tap do |i|
        i.id = id
        i.name = 'abc'
        i.timestamp = Time.now.to_i
        i.number = 5
      end
    end
    it 'should call set on the repository' do
      expect_any_instance_of(ElasticSearchFramework::Repository).to receive(:set).with(id: id, entity: item, index: ExampleIndex, type: type)
      ExampleIndex.put_item(id: id, type: type, item: item)
    end
  end

  describe '#delete_item' do
    let(:id) { 10 }
    let(:type) { 'default' }
    it 'should call drop on the repository' do
      expect_any_instance_of(ElasticSearchFramework::Repository).to receive(:drop).with(index: ExampleIndex, id: id, type: type)
      ExampleIndex.delete_item(id: id, type: type)
    end
  end

end
