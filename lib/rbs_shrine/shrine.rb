# frozen_string_literal: true

require "rbs"
require "rbs_rails"

module RbsShrine
  module Shrine
    def self.all
      ActiveRecord::Base.descendants.select { |model| model.ancestors.any?(::Shrine::Attachment) }
    end

    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass, :klass_name

      def initialize(klass)
        @klass = klass
        @klass_name = RbsRails::Util.module_name(klass)
      end

      def generate
        RbsRails::Util.format_rbs klass_decl
      end

      private

      def klass_decl
        <<~RBS
          #{header}
            #{methods}
          #{footer}
        RBS
      end

      def header
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = RbsRails::Util.module_name(superclass)

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def footer
        "end\n" * klass.module_parents.size
      end

      def methods
        attachments.reverse.map do |attachment|
          name = attachment.attachment_name
          <<~RBS
            def #{name}: () -> Shrine::UploadedFile
            def #{name}=: (IO | String | Hash[untyped, untyped]) -> Shrine::UploadedFile
            def #{name}_changed: () -> bool
            def #{name}_url: () -> String
          RBS
        end.join("\n")
      end

      def attachments
        @klass.ancestors.filter_map { |mod| mod if mod.is_a? ::Shrine::Attachment }
      end
    end
  end
end
