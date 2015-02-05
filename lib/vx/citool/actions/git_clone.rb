module Vx
  module Citool
    module Actions

      def invoke_git_clone(args, options = {})
        # We don't want to remove anything by mistake and our repos are so big
        #unless args["dest"].to_s.strip != ""
        #  re = invoke_shell("rm -rf #{args["dest"]}", silent: true, hidden: true)
        #end

        re = invoke_shell("command" => "if [ -d #{args["dest"]}/.git ]; then echo 'fetch'; else echo 'clone'; fi")
        return re unless re.success?
        cmd = re.data.strip == "fetch" ? fetch_cmd(args) : clone_cmd(args)

        re = invoke_shell_retry(cmd)
        return re unless re.success?

        if pr = args["pr"]
          re = invoke_shell("command" => "git fetch origin +refs/pull/#{pr}/head", "chdir" => args["dest"])
          return re unless re.success?

          re = invoke_shell("command" => "git checkout -q FETCH_HEAD", "chdir" => args["dest"])
          return re unless re.success?
        else
          re = invoke_shell("command" => "git checkout -qf #{args["sha"]}", "chdir" => args["dest"])
          return re unless re.success?
        end

        re
      end

      private

      def clone_cmd(args)
        cmd = "git clone --depth=50"

        if args["branch"] and !args["pr"]
          cmd << " --branch #{args["branch"]}"
        end

        cmd << " #{args["repo"]} #{args["dest"]}"
        cmd
      end

      def fetch_cmd(args)
        "git clean -q -d -x -f && git fetch -q origin && git fetch --tags -q origin && git reset -q --hard #{args["sha"]}"
      end
    end

  end
end
