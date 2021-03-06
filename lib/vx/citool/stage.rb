require 'benchmark'

module Vx
  module Citool
    class Stage

      include Citool::Log

      attr_reader :name, :environment, :chdir, :tasks, :vars

      def initialize(options)
        @name        = options["name"]        || "default"
        @environment = options["environment"] || {}
        @chdir       = options["chdir"]
        @tasks       = options["tasks"]       || []
        @vars        = options["vars"]        || {}
      end

      def teardown?
        name == 'teardown'
      end

      def script?
        name == 'script'
      end

      def after_success?
        name == 'after_success'
      end

      def invoke
        log_stage name do
          if chdir
            re = a.invoke_chdir(chdir)
            return re unless re.success?
          end

          environment.each_pair do |name, value|
            value = a.normalize_env_value(value)
            if value[0] == "!"
              value = value[1..-1]
            else
              log_command "export #{name}=#{value}"
            end
            ENV[name] = value
          end

          invoke_tasks
        end
      end

      def invoke_tasks
        re = nil
        tasks.each do |task|
          k,v = Array(task).first
          log_debug "#{k} | #{v.inspect}"
          re = invoke_action(k, v)

          if re.success?
            log_debug "#{k} | success"
          else
            log_debug "#{k} | fail"
          end

          if !after_success? && !re.success?
            break
          end
        end
        re || a::Succ.new(0, "stage #{name} successfuly completed")
      end

      def tasks?
        tasks.any?
      end

      def a
        Actions
      end

      def invoke_action(name, params)
        a.method("invoke_#{name}").call(params, vars: vars)
      end

    end
  end
end
