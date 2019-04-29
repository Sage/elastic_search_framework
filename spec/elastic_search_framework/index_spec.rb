RSpec.describe ElasticSearchFramework::Index do
  describe '#description' do
    it 'should return the index details' do
      expect(ExampleIndex.description).to be_a(Hash)
      expect(ExampleIndex.description[:name]).to eq 'example_index'
      expect(ExampleIndex.description[:id]).to eq :id
      expect(ExampleIndexWithId.description[:id]).to eq :number
    end
  end

  describe '#index' do
    before { ExampleIndex.create unless ExampleIndex.exists? }
    context 'when the instance variable is not defined' do
      before { allow(ExampleIndex).to receive(:instance_variable_defined?).and_return(true) }
      it 'raises an index error' do
        expect { ExampleIndex.index(name: 'test') }.to raise_error(
          ElasticSearchFramework::Exceptions::IndexError,
          '[Class] - Duplicate index description. Name: test.'
        )
      end
    end
  end

  describe '#id' do
    context 'when the instance variable is not defined' do
      before { allow(ExampleIndex).to receive(:instance_variable_defined?).and_return(true) }
      it 'raises an index error' do
        expect { ExampleIndex.id('name') }.to raise_error(
          ElasticSearchFramework::Exceptions::IndexError,
          "[Class] - Duplicate index id. Field: name."
        )
      end
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

    context 'when the namespace is nil' do
      before { ElasticSearchFramework.namespace = nil }

      it 'returns the description name downcased' do
        expect(ExampleIndex.full_name).to eq 'example_index'
      end
    end
  end

  describe '#mapping' do
    it 'should add mapping details to the index definition' do
      mappings = ExampleIndex.mappings
      expect(mappings).to be_a(Hash)
      expect(mappings.length).to eq 1
      expect(mappings['default'][:name][:type]).to eq :keyword
      expect(mappings['default'][:name][:index]).to eq true
    end
  end

  describe '#analysis' do
    context 'when analysis is nil' do
      before { ExampleIndex.delete if ExampleIndex.exists? }

      it 'does not add analysis to the index' do
        ExampleIndex.create
        expect(ExampleIndexWithSettings.get.dig('example_index', 'settings', 'index', 'analysis')).to be_nil
      end
    end

    context 'when analysis is not nil' do
      before { ExampleIndexWithSettings.delete if ExampleIndexWithSettings.exists? }
      let(:expected) do
        {
          'normalizer' => {
            'custom_normalizer' => {
              'filter' => ['lowercase'],
              'type' => 'custom'
            }
          },
          'analyzer' => {
            'custom_analyzer' => {
              'filter' => ['lowercase'],
              'type' => 'custom',
              'tokenizer' => 'standard'
            }
          }
        }
      end

      it 'adds analysis to the index' do
        ExampleIndexWithSettings.create
        expect(ExampleIndexWithSettings.get.dig('example_index', 'settings', 'index', 'number_of_shards')).to eq('1')
        expect(ExampleIndexWithSettings.get.dig('example_index', 'settings', 'index', 'analysis')).to eq(expected)
      end
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
    context 'when index is valid and does not exist' do
      before { ExampleIndex.delete if ExampleIndex.exists? }

      it 'should create an index' do
        expect(ExampleIndex.exists?).to be false
        ExampleIndex.create
        expect(ExampleIndex.exists?).to be true
      end

      after do
        ExampleIndex.delete
      end
    end

    context 'when index is not valid' do
      before { allow(ExampleIndex).to receive(:valid?).and_return(false) }

      it 'raises an error' do
        expect(ExampleIndex.exists?).to be false
        expect { ExampleIndex.create }.to raise_error(
          ElasticSearchFramework::Exceptions::IndexError,
          '[Class] - Invalid Index description specified.'
        )
      end
    end

    context 'when index is valid but already exists' do
      before { ExampleIndex.delete if ExampleIndex.exists? }

      it 'does not try to create a new index' do
        allow(ExampleIndex).to receive(:exists?).and_return(true)
        expect(ExampleIndex).not_to receive(:put)
        ExampleIndex.create
      end
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

  describe '#put' do
    let(:payload) { {} }
    context 'when there is a valid response' do
      before { allow(ExampleIndex).to receive(:is_valid_response?).and_return(true) }

      it 'returns true' do
        ExampleIndex.create
        expect(ExampleIndex.put(payload: payload)).to eq true
      end
    end

    context 'when there is not a valid response' do
      before { allow(ExampleIndex).to receive(:is_valid_response?).and_return(false) }

      context 'when the error is "index_already_exists_exception"' do
        let(:response_body) { { error: { root_cause: [{ type: 'index_already_exists_exception' }] } } }
        let(:request) { double }

        before { ExampleIndex.delete if ExampleIndex.exists? }
        it 'returns true' do
          allow(request).to receive(:body).and_return(response_body.to_json)
          allow(request).to receive(:code).and_return(404)
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(request)
          expect(ExampleIndex.put(payload: payload)).to eq true
        end
      end

      context 'when the error is not "index_already_exists_exception"' do
        let(:response_body) { { error: { root_cause: [{ type: 'foo' }] } } }
        let(:request) { double }
        it 'raises an IndexError' do
          allow(request).to receive(:body).and_return(response_body.to_json)
          allow(request).to receive(:code).and_return(404)
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(request)
          expect { ExampleIndex.put(payload: payload) }.to raise_error(
            ElasticSearchFramework::Exceptions::IndexError
          )
        end
      end
    end
  end

  describe '#is_valid_response?' do
    let(:code) { 200 }
    context 'when a 200 response code is returned' do
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(code)).to be true
      end
    end
    context 'when a 201 response code is returned' do
      let(:code) { 201 }
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(code)).to be true
      end
    end
    context 'when a 202 response code is returned' do
      let(:code) { 202 }
      it 'should return true' do
        expect(ExampleIndex.is_valid_response?(code)).to be true
      end
    end
    context 'when a 400 response code is returned' do
      let(:code) { 400 }
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(code)).to be false
      end
    end
    context 'when a 401 response code is returned' do
      let(:code) { 401 }
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(code)).to be false
      end
    end
    context 'when a 500 response code is returned' do
      let(:code) { 500 }
      it 'should return false' do
        expect(ExampleIndex.is_valid_response?(code)).to be false
      end
    end
  end

  describe '#host' do
    it 'should return the expected host based on default host & port values' do
      expect(ExampleIndex.host).to eq "#{ElasticSearchFramework.host}:#{ElasticSearchFramework.port}"
    end
  end

  describe '#repository' do
    it 'should return a ElasticSearchFramework::Repository instance' do
      expect(ExampleIndex.repository).to be_a(ElasticSearchFramework::Repository)
    end
    it 'should return the same ElasticSearchFramework::Repository instance for multiple calls' do
      expect(ExampleIndex.repository).to eq ExampleIndex.repository
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
      expect_any_instance_of(ElasticSearchFramework::Repository).to receive(:set).with(entity: item, index: ExampleIndex, type: type)
      ExampleIndex.put_item(type: type, item: item)
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
