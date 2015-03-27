require 'redmine_advanced_issue_history/hooks/controller_issues_new_after_save_hook'
require 'redmine_advanced_issue_history/hooks/issue_history_tab_hook'
require 'redmine_advanced_issue_history/patches/issue_relations_patch'
require 'redmine_advanced_issue_history/patches/issues_helper_patch'
require 'redmine_advanced_issue_history/patches/watcher_patch'
require 'redmine_advanced_issue_history/patches/journal_patch'

Redmine::Plugin.register :redmine_advanced_issue_history do
  name 'Redmine Advanced Issue History plugin'
  author 'Ilya Nemihin'
  description 'New events store in Issue history'
  version '0.1'
  url 'https://github.com/nemilya/redmine_advanced_issue_history'
  author_url ''
end

def add_system_journal(notes, issue)
  journal_detail_ids = []
  notes.each do |note|
    journal_details = JournalDetail.new
    journal_details.property = 'system'
    journal_details.prop_key = 'system'
    journal_details.value = note
    journal_details.save!
    journal_detail_ids.append(journal_details.id)
  end
  journal = Journal.new(:journalized => issue, :user => User.current, :notes => "")
  journal.detail_ids = journal_detail_ids
  journal.save!
end