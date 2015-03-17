# encoding: utf-8

require_dependency 'issues_helper'

module IssuesHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :show_detail, :advanced
    end
  end

  module InstanceMethods
    def show_detail_with_advanced(detail, no_html=false, options={})
      if detail.property == 'system'
        return detail.value
      else
        return show_detail_without_advanced(detail, no_html=false, options={})
      end

    end
  end
end

IssuesHelper.send(:include, IssuesHelperPatch)
