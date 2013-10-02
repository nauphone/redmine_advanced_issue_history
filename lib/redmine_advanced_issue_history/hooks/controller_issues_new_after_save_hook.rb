#encoding: utf-8
module RedmineAdvancedIssueHistory
  module Hooks
    class ControllerIssuesNewAfterSaveHook < Redmine::Hook::ViewListener
      # Context:
      # * :issue => Issue being saved
      # * :params => HTML parameters
      #

      def controller_issues_edit_before_save(context={})
        issue = context[:issue]
        issue_params = context[:params][:issue]
        if issue.parent.present? && (issue.parent.id != issue_params[:parent_issue_id].try(:to_i))
          note = "Sub task '#{issue}' has been removed"
          journal = Journal.new(:journalized => issue.parent, :user => User.current, :notes => note, :is_system_note => true)
          journal.save
        end
        if issue_params[:parent_issue_id].present? && (issue.parent.try(:id) != issue_params[:parent_issue_id].to_i)
          note = "Sub task '#{issue}' was added"
          journal = Journal.new(:journalized => Issue.find(issue_params[:parent_issue_id]), :user => User.current, :notes => note, :is_system_note => true)
          journal.save
        end
        if issue.closed? and !issue.relations_from.empty?
          issue.relations_from.each do |relation|
            if relation.relation_type == IssueRelation::TYPE_BLOCKS
              blocked_issue = relation.issue_to_id
              note = "Blocking task '#{issue}' was closed"
              journal = Journal.new(:journalized => Issue.find(blocked_issue), :user => User.current, :notes => note, :is_system_note => true)
              journal.save
            end
          end
        end
      end

      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        unless issue.parent.nil?
          parent_issue = issue.parent
          user = User.current
          parent_task_note = "Sub task '#{issue}' was added"
          sub_task_note = "Has been added as sub task to '#{parent_issue}'"

          parent_task_journal  = Journal.new(:journalized => parent_issue, :user => user, :notes => parent_task_note, :is_system_note=> true)
          sub_task_journal = Journal.new(:journalized => issue, :user => user, :notes => sub_task_note, :is_system_note=> true)
          parent_task_journal.save && sub_task_journal.save
        end
      end
    end
  end
end
