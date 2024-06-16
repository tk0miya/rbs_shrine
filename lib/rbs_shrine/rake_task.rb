# frozen_string_literal: true

require "rake/tasklib"

module RbsShrine
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :signature_root_dir

    def initialize(name = :'rbs:shrine', &block)
      super()

      @name = name
      @signature_root_dir = Rails.root / "sig/rbs_shrine"

      block&.call(self)

      define_generate_task
      define_clean_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_shrine"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_clean_task
      desc "Clean RBS files for shrine models"
      task "#{name}:clean" do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end

    def define_generate_task
      desc "Generate RBS files for shrine models"
      task("#{name}:generate": :environment) do
        require "rbs_shrine/shrine" # load RbsShrine lazily

        Rails.application.eager_load!

        RbsShrine::Shrine.all.each do |klass|
          rbs = RbsShrine::Shrine.class_to_rbs(klass)
          path = signature_root_dir / "#{klass.name.underscore}.rbs"
          path.dirname.mkpath
          path.write(rbs)
        end
      end
    end
  end
end
