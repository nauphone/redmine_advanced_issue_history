module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          after_commit :notification_relations_if_create, on: :create
          after_destroy :notification_relations_if_destroy
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def notification_relations_if_create
          note = "Relation '#{self.relation_type}' to '#{self.issue_to}' was created"
          add_system_journal([note], self.issue_from)

          note = "Relation '#{self.relation_type}' to '#{self.issue_from}' was created"
          add_system_journal([note], self.issue_to)
        end

        def notification_relations_if_destroy
          note = "Relation '#{self.relation_type}' to '#{self.issue_to}' was destroyed"
          add_system_journal([note], self.issue_from)

          note = "Relation '#{self.relation_type}' to '#{self.issue_from}' was destroyed"
          add_system_journal([note], self.issue_to)
        end

      end
    end
  end
end
IssueRelation.send(:include, RedmineAdvancedIssueHistory::Patches::IssueRelationPatch)