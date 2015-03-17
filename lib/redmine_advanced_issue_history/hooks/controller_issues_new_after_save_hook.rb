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
        notes_by_issue = {}
        issue_params = context[:params][:issue]
        if issue.parent.present? && (issue.parent.id != issue_params[:parent_issue_id].try(:to_i))
          notes_by_issue[issue.parent] ||= []
          notes_by_issue[issue.parent] << "Sub task '#{issue}' has been removed"
        end
        if issue_params[:parent_issue_id].present? && (issue.parent.try(:id) != issue_params[:parent_issue_id].to_i)
          notes_by_issue[Issue.find(issue_params[:parent_issue_id])] ||= []
          notes_by_issue[Issue.find(issue_params[:parent_issue_id])] << "Sub task '#{issue}' was added"
        end
        if issue.closed? and !issue.relations_from.empty?
          issue.relations_from.each do |relation|
            if relation.relation_type == IssueRelation::TYPE_BLOCKS
              notes_by_issue[Issue.find(blocked_issue)] ||= []
              notes_by_issue[Issue.find(blocked_issue)] << "Blocking task '#{issue}' was closed"
            end
          end
        end
        unless issue.parent.nil?
          parent_issue = issue.parent
          open_issues = parent_issue.descendants.reject {|x| x if x.closed? or x == issue}
          unless IssueStatus.find(issue_params[:status_id].to_i).is_closed?
            open_issues.append(issue)
          end if :status_id.in? issue_params
          unless open_issues.any?
            notes_by_issue[parent_issue] ||= []
            notes_by_issue[parent_issue] << "All subtasks were closed"
          end
        end
        notes_by_issue.each do |issue,notes|
          add_system_journal(notes, issue)
        end
      end

      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        notes_by_issue = {}
        unless issue.parent.nil?
          parent_issue = issue.parent
          notes_by_issue[parent_issue] ||= []
          notes_by_issue[parent_issue] << "Sub task '#{issue}' was added"
          notes_by_issue[issue] ||= []
          notes_by_issue[issue] << "Has been added as sub task to '#{parent_issue}'"
        end
        unless issue.parent.nil?
          parent_issue = issue.root
          open_issues = parent_issue.descendants.reject {|x| x if x.closed? }
          unless open_issues.any?
            notes_by_issue[parent_issue] ||= []
            notes_by_issue[parent_issue] << "All subtasks were closed"
          end
        end
        notes_by_issue.each do |issue,notes|
          add_system_journal(notes, issue)
        end
      end
    end
  end
end
