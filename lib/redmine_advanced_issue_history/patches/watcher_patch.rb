require_dependency 'plugins/acts_as_watchable/lib/acts_as_watchable.rb'

module RedmineAdvancedIssueHistory
  module Patches
    module WatcherPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :remove_watcher, :advanced
        end
      end

      module InstanceMethods

        def remove_watcher_with_advanced(user)
          ret = remove_watcher_without_advanced(user)
          unless ret.nil?
            note = "Watcher #{user.name} was removed"
            add_system_journal([note], Issue.find(self.id))
          end
          return ret
        end

      end
    end
  end
end
Redmine::Acts::Watchable::InstanceMethods.send(:include, RedmineAdvancedIssueHistory::Patches::WatcherPatch) 

module RedmineAdvancedIssueHistory
  module Patches
    module WatchersControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :create, :advanced
        end
      end

      module InstanceMethods
        def create_with_advanced
          user_ids = []
          notes = []
          if params[:watcher].is_a?(Hash)
            user_ids << (params[:watcher][:user_ids] || params[:watcher][:user_id])
          else
            user_ids << params[:user_id]
          end
          user_ids = user_ids.flatten.compact.uniq
          if user_ids.any?
            user_ids.each do |user_id|
              user = User.find(user_id)
              @watched.add_watcher(user)
              notes.append("Watcher #{user.name} was added")
            end
          end
          add_system_journal(notes, @watched)
          @watched.reload
          respond_to do |format|
            format.html { redirect_to_referer_or {render :text => 'Watcher added.', :layout => true}}
            format.js
            format.api { render_api_ok }
          end

        end
      end

    end
  end
end
WatchersController.send(:include, RedmineAdvancedIssueHistory::Patches::WatchersControllerPatch)