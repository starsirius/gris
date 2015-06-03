module Gris
  module SortHelpers
    extend ActiveSupport::Concern

    def sort_order(options = {})
      params[:sort] = options[:default_sort_order] unless params[:sort]
      return [] unless params[:sort]
      sort_order = params[:sort].to_s
      unless options[:default_sort_order] == sort_order
        supported_sort_orders = route_sort
        error!("This API doesn't support sorting", 400) if supported_sort_orders.blank?
        supported_sort_orders = supported_sort_orders.keys if supported_sort_orders.is_a?(Hash)
        unless supported_sort_orders.include?(sort_order)
          error!("Invalid sort order: #{sort_order}, must be#{supported_sort_orders.count == 1 ? '' : ' one of'} '#{supported_sort_orders.join('\', \'')}'", 400)
        end
      end
      sort_order = sort_order.split(',').map do |sort_entry|
        sort_order = {}
        if sort_entry[0] == '-'
          sort_order[:direction] = :desc
          sort_order[:column] = sort_entry[1..-1]
        else
          sort_order[:direction] = :asc
          sort_order[:column] = sort_entry
        end
        error!("Invalid sort: #{sort_entry}", 400) if sort_order[:column].blank?
        sort_order
      end
      sort_order
    end

    def route_sort
      (env['api.endpoint'].route_setting(:sort) || {})[:sort]
    end

    def sort(coll, options = {})
      sort_order = sort_order(options)
      unless sort_order.empty?
        if coll.respond_to?(:order)
          coll = coll.order(Hash[sort_order.map { |s| [s[:column], s[:direction] == :asc ? :asc : :desc] }])
        else
          error!("Cannot sort #{coll.class.name}", 500)
        end
      end
      coll.is_a?(Module) && coll.respond_to?(:all) ? coll.all : coll
    end
  end
end
