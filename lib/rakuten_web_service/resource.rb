# frozen_string_literal: true

require 'rakuten_web_service/client'
require 'rakuten_web_service/search_result'

require 'rakuten_web_service/string_support'

module RakutenWebService
  class Resource
    attr_reader :params

    using RakutenWebService::StringSupport

    class << self
      # @private
      def inherited(subclass)
        @@subclasses ||= []
        @@subclasses.push(subclass)
      end

      # @private
      def subclasses
        @@subclasses || []
      end

      # @private
      def attribute(*attribute_names)
        attribute_names.each do |attribute_name|
          attribute_name = attribute_name.to_s

          define_getter_for_attribute(attribute_name)
          next unless attribute_name.end_with?('Flag')

          define_asking_method_for_attribute(attribute_name)
        end
      end

      def search(options)
        SearchResult.new(options, self)
      end

      def all(options, &block)
        if block
          search(options).all(&block)
        else
          search(options).all
        end
      end

      # @private
      def resource_name
        @resource_name ||= name.split('::').last.downcase
      end

      # @private
      def set_resource_name(name)
        @resource_name = name
      end

      # @!macro [attach] resource.endpoin
      #   @!method endpoint
      #   Returns this resource class's endpoint.
      #   @return [String] endoint URL
      #   @see $1
      def endpoint(url = nil)
        @endpoint = url || @endpoint
      end

      # @private
      def set_parser(&block)
        instance_eval do
          define_singleton_method :parse_response, block
        end
      end

      private

      def define_getter_for_attribute(attribute_name)
        method_name = attribute_name.to_snake
        method_name.sub!(/^#{resource_name}_(\w+)$/, '\1')

        define_method method_name do
          get_attribute(attribute_name)
        end
      end

      def define_asking_method_for_attribute(attribute_name)
        method_name = attribute_name.to_snake
        method_name.sub!(/^#{resource_name}_(\w+)$/, '\1')
        method_name.sub!(/(.+)_flag$/, '\1')

        define_method "#{method_name}?" do
          get_attribute(attribute_name) == 1
        end
      end
    end

    def initialize(params)
      @params = {}
      params.each { |k, v| @params[k.to_s] = v }
    end

    def [](key)
      camel_key = key.to_camel
      # camel_key[0] = camel_key[0].downcase
      @params[key] || @params[camel_key]
    end

    def get_attribute(name)
      @params[name.to_s]
    end

    def attributes
      params.keys
    end

    def ==(other)
      raise ArgumentError unless other.is_a?(RakutenWebService::Resource)

      params.keys.all? do |k|
        @params[k] == other.params[k]
      end
    end
  end
end
