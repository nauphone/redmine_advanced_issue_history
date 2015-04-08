# encoding: utf-8

require_dependency 'issues_helper'

module IssuesHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :show_detail, :advanced
      alias_method_chain :users_for_new_issue_watchers, :advanced
    end
  end

  module InstanceMethods
    def show_detail_with_advanced(detail, no_html=false, options={})
      if detail.property == 'system'
        return detail.value
      else
        return show_detail_without_advanced(detail, no_html, options)
      end

    end

    def users_for_new_issue_watchers_with_advanced(issue)
      users = users_for_new_issue_watchers_without_advanced(issue)
      if issue.project.users.count > 20
        users = users + issue.project.users
      end
      users.sort_by(&:name)
    end

  end
end

IssuesHelper.send(:include, IssuesHelperPatch)
