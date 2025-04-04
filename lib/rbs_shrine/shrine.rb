# frozen_string_literal: true

require "rbs"
require_relative "utils"

module RbsShrine
  module Shrine
    def self.all #: Array[singleton(ActiveRecord::Base)]
      ActiveRecord::Base.descendants.select { |model| model.ancestors.any?(::Shrine::Attachment) }
    end

    # @rbs klass: singleton(ActiveRecord::Base)
    def self.class_to_rbs(klass) #: String
      Generator.new(klass).generate
    end

    class Generator
      include Utils

      attr_reader :klass #: singleton(ActiveRecord::Base)
      attr_reader :klass_name #: String

      # @rbs klass: singleton(ActiveRecord::Base)
      def initialize(klass) #: void
        @klass = klass
        @klass_name = klass.name || ""
      end

      def generate #: String
        format <<~RBS
          # resolve-type-names: false

          #{header}
            #{methods}
          #{footer}
        RBS
      end

      private

      def header #: String
        klass_to_names(klass).map do |name|
          mod_object = Object.const_get(name.to_s)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = superclass.name || "Object"

            "class #{name} < ::#{superclass_name}"
          when Module
            "module #{name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def footer #: String
        "end\n" * klass.module_parents.size
      end

      def methods #: String
        attachments.reverse.map do |attachment|
          name = attachment.attachment_name
          <<~RBS
            def #{name}: () -> ::Shrine::UploadedFile
            def #{name}=: (::IO | ::String | ::Hash[untyped, untyped]) -> ::Shrine::UploadedFile
            def #{name}_attacher: () -> ::Shrine::Attacher
            def #{name}_changed: () -> bool
            def #{name}_url: () -> ::String
          RBS
        end.join("\n")
      end

      def attachments #: Array[::Shrine::Attachment]
        @klass.ancestors.filter_map { |mod| mod if mod.is_a? ::Shrine::Attachment }
      end
    end
  end
end
