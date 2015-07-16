module RedmineAdvancedIssueHistory
  module Patches
    module JournalPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :css_classes, :history
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def css_classes_with_history
          css = css_classes_without_history
          if details.where(:prop_key => "system").any?
            css << " has-system"
          end
          if not details.where("prop_key != 'system'").any? and details.any?
            css = css.sub(' has-details', '')
          end
          css
        end

      end
    end
  end
end
Journal.send(:include, RedmineAdvancedIssueHistory::Patches::JournalPatch)