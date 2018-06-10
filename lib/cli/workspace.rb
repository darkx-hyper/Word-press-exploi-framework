# frozen_string_literal: true

module Cli
  # Provides functionality for interacting with workspaces.
  module Workspace
    def initialize
      super

      self.active_workspace = Models::Workspace.first(name: 'default')
    end

    def workspace(*args)
      return list_workspaces if args.length.zero?

      case args[0]
      when '-a'
        add_workspace(args[1])
      when '-d'
        delete_workspace(args[1])
      else
        switch_workspace(args[0])
      end
    end

    def workspaces
      Models::Workspace.all
    end

    def add_workspace(name)
      unless Models::Workspace.where(name: name).count.zero?
        return print_warning "#{name} already exists"
      end

      begin
        Models::Workspace.create(name: name)
        return print_good "Added workspace: #{name}"
      rescue Sequel::ValidationFailed
        print_warning 'Workspace names may only contain 1-50 alphanumeric characters and underscores'
      end
    end

    def list_workspaces
      workspaces.each do |workspace|
        if workspace.id == active_workspace.id
          print_info "#{workspace.name} #{'(active)'.green}"
        else
          print_info workspace.name
        end
      end
    end

    def switch_workspace(name)
      next_workspace = Models::Workspace.first(name: name)

      if next_workspace
        self.active_workspace = next_workspace
        context.module.active_workspace = active_workspace if context&.module
        print_good "Switched to workspace: #{name}"
      else
        print_bad "#{name} is not a valid workspace"
      end
    end

    def delete_workspace(name)
      if name == 'default'
        print_warning 'You cannot delete the default workspace'
        return
      end

      current_name = active_workspace.name
      Models::Workspace.where(name: name).destroy
      print_good "Deleted workspace: #{name}"
      switch_workspace 'default' if name == current_name
    end

    attr_accessor :active_workspace
  end
end
