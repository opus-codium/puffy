# frozen_string_literal: true

require 'core_ext'

RSpec.describe Hash do
  describe '#expand' do
    describe 'No expansion' do
      subject { { a: :b }.expand }

      it { is_expected.to eq([{ a: :b }]) }
    end

    describe 'Single expansion' do
      subject(:expanded_hash) { { a: %i[b c] }.expand }

      it do
        expect(expanded_hash).to eq([
                                      { a: :b },
                                      { a: :c },
                                    ])
      end
    end

    describe 'Multiple expansions' do
      subject(:expanded_hash) { { a: %i[b c], d: %i[e f] }.expand }

      it do
        expect(expanded_hash).to eq([
                                      { a: :b, d: :e },
                                      { a: :c, d: :e },
                                      { a: :b, d: :f },
                                      { a: :c, d: :f },
                                    ])
      end
    end

    describe 'Nested Array expansions' do
      subject(:expanded_hash) { { a: [{ b: { c: %i[d e] } }] }.expand }

      it do
        expect(expanded_hash).to eq([
                                      { a: { b: { c: :d } } },
                                      { a: { b: { c: :e } } },
                                    ])
      end
    end

    describe 'Nested Hash expansions' do
      subject(:expanded_hash) { { a: [{ b: [{ c: :d }, { e: :f }] }] }.expand }

      it do
        expect(expanded_hash).to eq([
                                      { a: { b: { c: :d } } },
                                      { a: { b: { e: :f } } },
                                    ])
      end
    end
  end
end
