begin
  require 'builder'
rescue LoadError
  gem 'builder'
  require 'builder'
end

module Cucumber
  module Formatter
    class JUnit < Cucumber::Ast::Visitor
    
      @reportdir = "./build/reports/"
    
      def initialize(step_mother, io, options)
        super(step_mother)
        @reportdir = options[:reportdir] if String === options[:reportdir]
      end
      
      def visit_feature(feature)
        @failures = @errors = @tests = 0
        @builder = Builder::XmlMarkup.new( :indent => 2 )
        super
              
        @testsuite = Builder::XmlMarkup.new( :indent => 2 )
        @testsuite.instruct!
        @testsuite.testsuite(
          :failures => @failures, 
          :errors => @errors, 
          :tests => @tests, 
          :name => @feature_name ) do
            @testsuite << @builder.target!
        end
        
        puts "Writing test output #{@feature_filename}"
        File.open(@feature_filename, 'w') { |file| file.write(@testsuite.target!) }
      end
      
      def visit_feature_name(name)
        lines = name.split(/\r?\n/)
        @feature_name = lines[0].sub(/Feature\:/, '').strip
        puts "Beginning #{lines[0]}"
        @feature_filename = convert_to_file_name(@feature_name)
      end
      
      def visit_scenario_name(keyword, name, file_colon_line, source_indent)
        puts "Running #{keyword}:#{name}"
        @scenario = name
      end
      
      def visit_steps(steps)
        @steps_failed = false
        super      
        @failures += 1 if @steps_failed
        @tests += 1
      end
      
      def visit_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        step_name = keyword + " " + step_match.format_args(lambda{|param| "*#{param}*"})
        @builder.testcase(:classname => "#{@feature_name}.#{@scenario}", :name => step_name) do
          if status != :passed
            @builder.failure(:message => step_name) do
              @builder.text!(format_exception(exception)) if exception
            end
            @steps_failed = true
          end
        end
      end    
      
      private
      
      def convert_to_file_name(value)
        @reportdir + "TEST-" + value.gsub(/[^\w_\.]/, '_') + ".xml"
      end
      
      def format_exception(exception)
        (["#{exception.message} (#{exception.class})"] + exception.backtrace).join("\n")
      end
    end

  end
end