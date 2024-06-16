# frozen_string_literal: true

require "rails"

module RbsShrine
  class InstallGenerator < ::Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_shrine.rake", <<~RUBY
        # frozen_string_literal: true

        begin
          require "rbs_shrine/rake_task"

          RbsShrine::RakeTask.new
        rescue LoadError
          # failed to load rbs_shrine. Skip to load rbs_shrine tasks.
        end
      RUBY
    end
  end
end
