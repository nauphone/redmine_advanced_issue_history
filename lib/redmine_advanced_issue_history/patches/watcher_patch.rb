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
        alias_method_chain :create_journal, :advanced_history
        alias_method_chain :init_journal, :advanced_history
        attr_accessor :issue_watchers_advanced_history_before_save
        end
      end

      module InstanceMethods
        def create_journal_with_advanced_history
          if self.current_journal.present?
            before = self.issue_watchers_advanced_history_before_save || []
            after = self.watcher_user_ids || []
            new_watchers = after - before
            new_users = []
            if !self.assigned_to.blank? and self.addable_watcher_users.include?(self.assigned_to)
              new_users.append(self.assigned_to)
              self.watcher_user_ids = self.watcher_user_ids | [self.assigned_to_id]
            end
            # Add the current user if they are addable
            if self.addable_watcher_users.include?(User.current) and !self.watcher_users.include?(User.current)
              new_users.append(User.current)
              self.watcher_user_ids = self.watcher_user_ids | [User.current.id]
            end

            if new_watchers.any?
              new_watchers.each do |principal_id|
                principal = Principal.find_by_id(principal_id)
                if principal.is_a?(User)
                  new_users.append(principal)
                end
                if principal.is_a?(Group)
                  new_users += principal.users
                end
              end
            end
            new_users = new_users.compact.uniq
            if new_users.compact.uniq.any?
              new_users.each do |user|
                self.current_journal.details << JournalDetail.new(:property => 'system',
                                                              :prop_key => 'system',
                                                              :value => "Watcher #{user.name} was added")
              end
            end
          end
          create_journal_without_advanced_history
        end

        def init_journal_with_advanced_history(user, notes = "")
          self.issue_watchers_advanced_history_before_save ||= self.watcher_user_ids
          init_journal_without_advanced_history(user, notes)
        end

      end
    end
  end
end
Issue.send(:include, RedmineAdvancedIssueHistory::Patches::IssuePatch)

module RedmineAdvancedIssueHistory
  module Patches
    module IssuesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
        alias_method_chain :build_new_issue_from_params, :advanced_history
        end
      end

      module InstanceMethods

        def build_new_issue_from_params_with_advanced_history
          build_new_issue_from_params_without_advanced_history
          if params.has_key?(:issue) and params[:issue].has_key?(:watcher_user_ids)
            @issue.issue_watchers_advanced_history_before_save = params[:issue][:watcher_user_ids]
          end
          @issue.init_journal(User.current)
        end

      end
    end
  end
end
IssuesController.send(:include, RedmineAdvancedIssueHistory::Patches::IssuesControllerPatch)