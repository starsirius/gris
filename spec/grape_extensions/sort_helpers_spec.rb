require 'spec_helper'
require 'active_record'

describe Gris::SortHelpers, type: :request do
  class Offer
    attr_accessor :to_email, :from_email
    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def persisted?
      false
    end
  end
  module Gris
    class SortTestApi
      include Gris::SortHelpers

      attr_reader :params, :route_sort

      def with_params(params = {})
        @params = params
        self
      end

      def without_params
        @params = {}
        self
      end

      def route
        self
      end

      def with_sort_order(sort_order)
        @route_sort = sort_order
        self
      end

      def error!(message, _code)
        fail message
      end
    end
  end
  before do
    @api = Gris::SortTestApi.new

    @john = Offer.new(to_email: 'john@email.com', from_email: 'chung-yi@artsymail.com')
    @bob = Offer.new(to_email: 'bob@email.com', from_email: 'barry@artsymail.com')
    @mark = Offer.new(to_email: 'mark@email.com', from_email: 'chung-yi@artsymail.com')
  end
  [[@john, @bob, @mark]].each do |coll|
    context 'sort' do
      it "doesn't do any sorting without a sort parameter" do
        expect(@api.without_params.sort(coll, {}).to_a).to eq [@john, @bob, @mark]
      end
      it 'sorts with default sort order without a sort parameter' do
        expect(@api
          .without_params
          .with_sort_order('from_email' => [])
          .sort(coll, default_sort_order: 'from_email').to_a).to eq [@bob, @john, @mark]
        expect(@api
          .without_params
          .with_sort_order('from_email,-to_email' => [])
          .sort(coll, default_sort_order: 'from_email,-to_email').to_a).to eq [@bob, @mark, @john]
      end
      it 'sorts given a single sort parameter' do
        expect(@api
          .with_sort_order('to_email' => [])
          .with_params(sort: 'to_email').sort(instance_eval(coll), {}).to_a).to eq [@bob, @john, @mark]
        expect(@api
          .with_sort_order('-to_email' => [])
          .with_params(sort: '-to_email').sort(instance_eval(coll), {}).to_a).to eq [@mark, @john, @bob]
      end
      it 'sorts given a pair of sort parameters' do
        expect(@api
          .with_sort_order('-from_email,to_email' => [])
          .with_params(sort: '-from_email,to_email').sort(instance_eval(coll), {}).to_a).to eq [@john, @mark, @bob]
        expect(@api
          .with_sort_order('from_email,-to_email' => [])
          .with_params(sort: 'from_email,-to_email').sort(instance_eval(coll), {}).to_a).to eq [@bob, @mark, @john]
      end
      it 'fails with an invalid sort parameter' do
        expect do
          @api.with_params(sort: '-').sort(instance_eval(coll))
        end.to raise_error("This API doesn't support sorting")
      end
      it 'fails without an exact sort match' do
        expect do
          @api
            .with_sort_order('from_email,-to_email' => [])
            .with_params(sort: 'from_email,to_email').sort(instance_eval(coll), {})
        end.to raise_error("Invalid sort order: from_email,to_email, must be 'from_email,-to_email'")
      end
      it "doesn't check default_sort_order" do
        expect do
          @api
            .with_params(sort: 'default').sort(instance_eval(coll), default_sort_order: 'default')
        end.not_to raise_error
      end
      it 'fails without an exact sort match with multiple sorts avaialable' do
        expect do
          @api
            .with_sort_order('to_email' => [], '-from_email,to_email' => [])
            .with_params(sort: 'from_email,to_email').sort(instance_eval(coll), {})
        end.to raise_error("Invalid sort order: from_email,to_email, must be one of 'to_email', '-from_email,to_email'")
      end
      it 'fails without a sort order' do
        expect do
          @api
            .with_params(sort: 'to_email').sort(instance_eval(coll), {})
        end.to raise_error("This API doesn't support sorting")
      end
    end
  end
end
