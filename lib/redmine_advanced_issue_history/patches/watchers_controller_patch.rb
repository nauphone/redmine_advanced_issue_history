module RedmineAdvancedIssueHistory
  module Patches
    module WatchersControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :destroy, :update_history
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def destroy_with_update_history
          @watched.set_watcher(User.find(params[:user_id]), false)

          # ilya
          if @watched.class.name == 'Issue'
              issue = @watched
              user = User.current
              watcher = User.find(params[:user_id])
              note = "Watcher #{watcher.name} was removed"
              journal = Journal.new(:journalized => issue, :user => user, :notes => note, :is_system_note=> true)
              journal.save
            end
          # /ilya

          respond_to do |format|
            format.html { redirect_to :back }
            format.js           
	  end
        end
      end
    end
  end
end
