# frozen_string_literal: true

require "active_record"
require "shrine"
require "rbs_shrine"

class Account < ActiveRecord::Base
  include Shrine::Attachment(:icon)
  include Shrine::Attachment(:small_icon)
end

class Article < ActiveRecord::Base
  include Shrine::Attachment(:cover_image)
end

RSpec.describe RbsShrine::Shrine do
  describe ".all" do
    subject { described_class.all }

    it "returns all ActiveRecord models with Shrine::Attachment" do
      is_expected.to contain_exactly(Account, Article)
    end
  end

  describe ".class_to_rbs" do
    subject { described_class.class_to_rbs(klass) }

    let(:klass) { Account }

    it "generates RBS" do
      rbs = <<~RBS
        class Account < ::ActiveRecord::Base
          def icon: () -> Shrine::UploadedFile
          def icon=: (IO | String | Hash[untyped, untyped]) -> Shrine::UploadedFile
          def icon_changed: () -> bool
          def icon_url: () -> String

          def small_icon: () -> Shrine::UploadedFile
          def small_icon=: (IO | String | Hash[untyped, untyped]) -> Shrine::UploadedFile
          def small_icon_changed: () -> bool
          def small_icon_url: () -> String
        end
      RBS

      is_expected.to eq(rbs)
    end
  end
end
