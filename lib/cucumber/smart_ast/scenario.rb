require 'cucumber/smart_ast/comments'
require 'cucumber/smart_ast/tags'
require 'cucumber/smart_ast/description'
require 'cucumber/smart_ast/scenario_step'

module Cucumber
  module SmartAst
    class Scenario
      include Comments
      include Tags
      include Description
      
      def initialize(keyword, description, line, tags, feature)
        @keyword, @description, @line, @tags, @feature = keyword, description, line, tags, feature
        @steps = []
      end

      def create_step(keyword, name, line)
        step = ScenarioStep.new(keyword, name, line)
        @steps << step
        step
      end

      def execute(step_mother, listener)
        step_mother.execute_unit(self, all_steps, listener)
      end

      def accept(visitor)
        visitor.visit_feature(@feature)
        visitor.visit_scenario(self)
      end

      def report_result(gherkin_listener)
        # NO-OP
      end

      def report_to(gherkin_listener)
        gherkin_listener.scenario(@keyword, @description, @line)
      end

      private
      
      def all_steps
        @feature.background_steps + @steps
      end
    end
  end
end