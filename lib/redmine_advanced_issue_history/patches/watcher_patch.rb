module RedmineAdvancedIssueHistory
  module Patches
    module WatcherPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def after_create
          if self.user_id && self.watchable_type == 'Issue'
            issue = self.watchable
            user = User.current
            note = "Watcher #{self.user.name} was added"
            journal = Journal.new(:journalized => issue, :user => user, :notes => note, :notify => false, :is_system_note=> true)
            journal.save
            if Setting.notified_events.include?('issue_updated') ||
                        (Setting.notified_events.include?('issue_note_added') && journal.notes.present?)
              Mailer.deliver_watcher_add(journal, self.user.mail)
            end
          end
        end

        # destroy is handled by controller patch
        # because of in watchable plugin the destroy id done by direct sql

      end
    end
  end
end
