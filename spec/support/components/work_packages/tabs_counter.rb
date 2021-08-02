require 'features/support/components/ui_autocomplete'

module Components
  module WorkPackages
    class Tabs
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::UIAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package)
        @work_package = work_package
      end

      # Check value of counter for the given tab
      def expect_counter(tab, content)
        expect(tab).to have_selector('.op-tab-count', text: content.to_s)
      end

      # Counter should not be displayed, if there are no relations or watchers
      def expect_no_counter(tab)
        expect(tab).to have_no_selector('.op-tab-count', wait: 10)
      end
    end
  end
end
