module RedmineAdvancedIssueHistory
  module RedmineIssueHistoryTabs
    class Hooks < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: 'hooks/issue_history_tabs', layout: false
    end
  end
end
