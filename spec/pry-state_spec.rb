require 'spec_helper'
require_relative "../lib/pry-state.rb"

describe "pry-state" do
  Given(:pry_instance) { Pry.new }
  Given(:config) { pry_instance.config.extra_sticky_locals[:pry_state] }
  Given(:hooks) { pry_instance.hooks }

  context "Set up" do
    context "Defaults" do
      Then { config.kind_of? PryState::Config }
      Then { !config.enabled? }
      Then {
        config.groups_visibility == PryState::Config::DEFAULT_GROUPS_VISIBILITY
      }
      Then { config.width == PryState::Config::WIDTH }
      Then { config.max_left_column_width == PryState::Config::MAX_LEFT_COLUMN_WIDTH }
      Then { config.column_ratio == PryState::Config::COLUMN_RATIO }
      Then { config.left_column_width == PryState::Config::LEFT_COLUMN_WIDTH }
      Then { config.right_column_width == PryState::Config::WIDTH - PryState::Config::LEFT_COLUMN_WIDTH }
      Then { !config.truncating? }
      Then { config.prev.empty? }
      Then { hooks.hook_exists? :before_session,  :state_hook }
    end
  end

  context "Output" do
    Given(:obj) {
      obj = Object.new
      class << obj
        attr_accessor :first_method, :second_method, :third_method
      end
      def obj.bing() @x=12; bong end
      def obj.bong() bang end
      def obj.bang() Pry.start(binding) end
      obj
    }
    long_var = '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80]'
    Given(:out) { StringIO.new }
    context "Given a default set up" do
      When {
        redirect_pry_io(
          # The no color line is here because setting it in the config
          # above seems to have no effect, so, that's why.
          InputTester.new("_pry_.config.color = false",
                          "state-truncate off",
                          "z = 14",
                          "ys = #{long_var}",
                          "state-show",
                          "exit-all"),
                          out
                        ) do
          obj.bing
        end
      }

      Then { config.prev.kind_of? Hash }
      Then { config.prev.keys == [:instance, :local] }
      Then { out.string.include? "global: false instance: true local: true truncating?: false" }
      Then { out.string.include? "@x        12" }
      Then { out.string.include? "z         14" }
      Then { out.string.include? "ys        len:80 #{long_var}" }
    end
    context "With the truncate on" do
      When {
        redirect_pry_io(
          # The no color line is here because setting it in the config
          # above seems to have no effect, so, that's why.
          InputTester.new("_pry_.config.color = false",
                          "state-truncate on",
                          "z = 14",
                          "ys = #{long_var}",
                          "state-show",
                          "exit-all"),
                          out
                        ) do
          obj.bing
        end
      }

      Then { config.prev.kind_of? Hash }
      Then { config.prev.keys == [:instance, :local] }
      Then { out.string.include? "global: false instance: true local: true truncating?: true" }
      Then { out.string.include?  "@x        12" }
      Then { out.string.include?  "z         14" }
      Then { !out.string.include? "ys        len:80 #{long_var}" }
      Then { out.string.include?  "ys        len:80 [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 1..." }
    end
  end

end