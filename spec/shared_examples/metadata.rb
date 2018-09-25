# frozen_string_literal: true

RSpec.shared_examples 'a resource with metadata' do
  let(:schema)   { instance_double(IronBank::Describe::Object) }
  let(:excluded) { %w[ExcludedField] }

  describe '#exclude_fields' do
    subject { described_class.exclude_fields }
    it { is_expected.to be_an(Array) }
  end

  describe '#fields' do
    subject { described_class.fields }

    context 'without a schema' do
      it { is_expected.to eq([]) }
    end

    context 'with a schema' do
      let(:fields) do
        [
          instance_double(IronBank::Describe::Field, name: 'AccountNumber'),
          instance_double(IronBank::Describe::Field, name: 'ExcludedField')
        ]
      end

      before do
        allow(IronBank::Schema).to receive(:for).and_return(schema)
        allow(schema).to receive(:fields).and_return(fields)
        allow(described_class).to receive(:exclude_fields).and_return(excluded)
      end

      after do
        # NOTE: Not resetting the instance variable here seems to leak the
        #       `instance_double(IronBank::Describe::Object)` to the other
        #       examples.
        described_class.instance_variable_set :@schema, nil
      end

      it { is_expected.to eq(%w[AccountNumber]) }
    end
  end

  describe '#query_fields' do
    subject { described_class.query_fields }

    context 'without a schema' do
      it { is_expected.to eq([]) }
    end

    context 'with a schema' do
      let(:query_fields) { %w[AccountNumber ExcludedField] }

      before do
        allow(IronBank::Schema).to receive(:for).and_return(schema)
        allow(schema).to receive(:query_fields).and_return(query_fields)
        allow(described_class).to receive(:exclude_fields).and_return(excluded)
      end

      after do
        # FIXME: Not resetting the instance variable here seems to leak the
        # `instance_double(IronBank::Describe::Object)` to the other examples.
        described_class.instance_variable_set :@schema, nil
      end

      it { is_expected.to eq(%w[AccountNumber]) }
    end
  end

  describe '#with_schema' do
    let(:fields)  { %w[AccountNumber MyCustomField__c] }
    let(:methods) { %i[account_number my_custom_field__c] }

    before do
      allow(described_class).to receive(:fields).and_return(fields)
    end

    subject(:with_schema) { described_class.with_schema }

    it 'defines Ruby-friendly instance methods' do
      with_schema
      expect(described_class.instance_methods).to include(*methods)
    end

    describe 'the defined methods' do
      let(:remote) do
        { 'MyCustomField__c' => 'custom-field-value-from-remote' }
      end

      before { with_schema }

      subject(:my_custom_field) do
        described_class.new(remote).my_custom_field__c
      end

      specify 'access the remote hash' do
        expect(my_custom_field).to eq('custom-field-value-from-remote')
      end
    end
  end
end