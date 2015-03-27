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
          users = User.active.visible.where(:id => user_ids.flatten.compact.uniq).to_a
          users.each do |user|
            Watcher.create(:watchable => @watched, :user => user)
            notes.append("Watcher #{user.name} was added")
          end
          add_system_journal(notes, @watched)

          respond_to do |format|
            format.html { redirect_to_referer_or {render :text => 'Watcher added.', :layout => true}}
            format.js { @users = users_for_new_watcher }
            format.api { render_api_ok }
          end
        end
      end

    end
  end
end
WatchersController.send(:include, RedmineAdvancedIssueHistory::Patches::WatchersControllerPatch)

module RedmineAdvancedIssueHistory
  module Patches
    module IssuePatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :watcher_user_ids=, :advanced
        end
      end

      module InstanceMethods

        def watcher_user_ids_with_advanced=(user_ids)
          notes = []
          user_ids.each do |user_id|
            principal = Principal.find_by_id(user_id)
            if principal.is_a?(User)
              notes.append("Watcher #{principal.name} was added")
            end
            if principal.is_a?(Group)
              principal.users.each do |pr_user|
                notes.append("Watcher #{pr_user.name} was added")
              end
            end
          end
          if notes.any?
            journal_detail_ids = []
            notes.each do |note|
              journal_details = JournalDetail.new
              journal_details.property = 'system'
              journal_details.prop_key = 'system'
              journal_details.value = note
              journal_details.save!
              journal_detail_ids.append(journal_details.id)
            end
            journal = Journal.new(:user => User.current, :notes => "", :notify => false)
            journal.detail_ids = journal_detail_ids
            journal.save!
            self.journal_ids=self.journal_ids | [journal.id]
          end
          send :watcher_user_ids_without_advanced=, user_ids
        end

      end
    end
  end
end
Issue.send(:include, RedmineAdvancedIssueHistory::Patches::IssuePatch)

