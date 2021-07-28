RSpec.describe ElasticSearchFramework::Index do
  describe '#full_name' do
    let(:namespace) { 'uat' }
    let(:namespace_delimiter) { '.' }
    before do
      ElasticSearchFramework.namespace = namespace
      ElasticSearchFramework.namespace_delimiter = namespace_delimiter
    end
    it 'should return the full index name including namespace and delimiter' do
      expect(ExampleIndexAlias.full_name).to eq "#{ElasticSearchFramework.namespace}#{ElasticSearchFramework.namespace_delimiter}example"
    end

    context 'when the namespace is nil' do
      before { ElasticSearchFramework.namespace = nil }

      it 'returns the description name downcased' do
        expect(ExampleIndexAlias.full_name).to eq 'example'
      end
    end
  end

  describe '#valid?' do
    context 'for a valid index definition' do
      it 'should return true' do
        expect(ExampleIndexAlias.valid?).to be true
      end
    end
    context 'for an invalid index definition' do
      it 'should return true' do
        expect(InvalidIndexAlias.valid?).to be false
      end
    end
  end

  describe '#create' do
    context 'when alias is valid and does not exist' do
      before do
        ExampleIndexAlias.delete
        ExampleIndex.delete if ExampleIndex.exists?
        ExampleIndex.create
      end

      it 'creates an alias for the active index' do
        expect(ExampleIndexAlias.exists?(index: ExampleIndex)).to be false
        ExampleIndexAlias.create
        expect(ExampleIndexAlias.exists?(index: ExampleIndex)).to be true
      end

      after do
        ExampleIndexAlias.delete
        ExampleIndex.delete
      end
    end

    context 'when alias is not valid' do
      before { allow(ExampleIndexAlias).to receive(:valid?).and_return(false) }

      it 'raises an error' do
        expect(ExampleIndexAlias.exists?(index: ExampleIndex)).to be false
        expect { ExampleIndexAlias.create }.to raise_error(
          ElasticSearchFramework::Exceptions::IndexError
        )
      end
    end

    context 'when alias is valid but already exists' do
      before do
        ExampleIndex.delete if ExampleIndex.exists?
        ExampleIndex.create
        ExampleIndexAlias.create
      end

      it 'does not try to create a new alias' do
        ExampleIndexAlias.create
      end

      after do
        ExampleIndexAlias.delete
        ExampleIndex.delete
      end
    end

    context 'when alias is valid and does not exist and requires updating' do
      before do
        ExampleIndexAlias.delete
        ExampleIndex.delete if ExampleIndex.exists?
        ExampleIndex2.delete if ExampleIndex2.exists?
        ExampleIndex.create
        ExampleIndex2.create
        ExampleIndexAlias.create
      end

      it 'modifies the alias to the active index' do
        expect(ExampleIndexAlias.exists?(index: ExampleIndex)).to be true
        ExampleIndexAlias2.create
        expect(ExampleIndexAlias.exists?(index: ExampleIndex)).to be false
        expect(ExampleIndexAlias2.exists?(index: ExampleIndex2)).to be true
      end

      after do
        ExampleIndexAlias.delete
        ExampleIndex.delete
        ExampleIndex2.delete
      end
    end
  end

  describe '#get_item' do
    let(:id) { 10 }
    let(:type) { 'default' }
    context 'when active index routing_enabled false' do
      it 'should call get on the repository' do
        expect(ExampleIndexAlias.repository).to receive(:get).with(index: ExampleIndexAlias, id: id, type: type).once
        ExampleIndexAlias.get_item(id: id, type: type)
      end

      it 'should call get on the repository and not pass through routing_key when supplied' do
        expect(ExampleIndexAlias.repository).to receive(:get).with(index: ExampleIndexAlias, id: id, type: type).once
        ExampleIndexAlias.get_item(id: id, type: type, routing_key: 5)
      end
    end

    context 'when active index routing_enabled true' do
      it 'should call get on the repository' do
        expect(ExampleIndexAlias2.repository).to receive(:get).with(index: ExampleIndexAlias2, id: id, type: type, routing_key: 5).once
        ExampleIndexAlias2.get_item(id: id, type: type, routing_key: 5)
      end
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
    context 'without specifying op_type' do
      it 'should call set on the repository for each index of the alias with default op_type (index)' do
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex, type: type, op_type: 'index').once
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex2, type: type, op_type: 'index', routing_key: 5).once
        ExampleIndexAlias.put_item(type: type, item: item, routing_key: 5)
      end
    end

    context 'with specified op_type' do
      it 'should call set on the repository for each index of the alias with supplied op_type (index)' do
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex, type: type, op_type: 'index').once
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex2, type: type, op_type: 'index', routing_key: 5).once
        ExampleIndexAlias.put_item(type: type, item: item, op_type: 'index', routing_key: 5)
      end

      it 'should call set on the repository for each index of the alias with supplied op_type (create)' do
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex, type: type, op_type: 'create').once
        expect(ExampleIndexAlias.repository).to receive(:set).with(entity: item, index: ExampleIndex2, type: type, op_type: 'create', routing_key: 5).once
        ExampleIndexAlias.put_item(type: type, item: item, op_type: 'create', routing_key: 5)
      end
    end
  end

  describe '#delete_item' do
    let(:id) { 10 }
    let(:type) { 'default' }
    it 'should call drop on the repository for each index of the alias' do
      expect(ExampleIndexAlias.repository).to receive(:drop).with(index: ExampleIndex, id: id, type: type).once
      expect(ExampleIndexAlias.repository).to receive(:drop).with(index: ExampleIndex2, id: id, type: type, routing_key: 5).once
      ExampleIndexAlias.delete_item(id: id, type: type, routing_key: 5)
    end
  end
end
