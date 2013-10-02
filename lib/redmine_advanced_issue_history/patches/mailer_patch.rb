module RedmineAdvancedIssueHistory
  module Patches
    module MailerPatch
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
        def watcher_add(journal, watcher)
          issue = journal.journalized.reload
          redmine_headers 'Project' => issue.project.identifier,
                          'Issue-Id' => issue.id,
                          'Issue-Author' => issue.author.login
          redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
          message_id journal
          references issue
          @author = journal.user
          recipients = [watcher]
          s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
          s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
          s << issue.subject
	  @issue = issue
	  @journal = journal
	  @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
	  mail :to => recipients,
	       :subject => s
        end
      end
    end
  end
end
