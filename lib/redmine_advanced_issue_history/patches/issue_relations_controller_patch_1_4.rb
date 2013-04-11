module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :create,  :update_history
          alias_method_chain :destroy, :update_history
          unloadable
          helper :journals
          helper :issues
          include JournalsHelper   
          include IssuesHelper   
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def create_with_update_history
          # based on redmine 1.4.4
          @relation = IssueRelation.new(params[:relation])
          @relation.issue_from = @issue
          if params[:relation] && m = params[:relation][:issue_to_id].to_s.strip.match(/^#?(\d+)$/)
            @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
          end
          saved = @relation.save

          # ilya
          if @relation.errors.empty? && request.post?
            note = "Relation '#{@relation.relation_type}' to '#{@relation.issue_to}' was created"
            journal = Journal.new(:journalized => @relation.issue_from, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save

            note = "Relation '#{@relation.relation_type}' to '#{@relation.issue_from}' was created"
            journal = Journal.new(:journalized => @relation.issue_to, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save
          end
          # /ilya

          respond_to do |format|
            format.html { redirect_to redirect_to issue_path(@issue) }
            format.js do
              @relations = @issue.reload.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
            end
            format.api {
              if saved
                render :action => 'show', :status => :created, :location => relation_url(@relation)
              else
                render_validation_errors(@relation)
              end
            }
          end
        end


        def destroy_with_update_history
          # based on redmine 1.4.4

          raise Unauthorized unless @relation.deletable?
          @relation.destroy

          # ilya
          note = "Relation '#{@relation.relation_type}' to '#{@relation.issue_to}' was destroyed"
          journal = Journal.new(:journalized => @relation.issue_from, :user => User.current, :notes => note, :is_system_note=> true)
          journal.save

          note = "Relation '#{@relation.relation_type}' to '#{@relation.issue_from}' was destroyed"
          journal = Journal.new(:journalized => @relation.issue_to, :user => User.current, :notes => note, :is_system_note=> true)
          journal.save
          # /ilya

          respond_to do |format|
            format.html { redirect_to issue_path(@relation.issue_from) } 
            format.js   
            format.api  { head :ok }
          end
        end


      end
    end
  end
end
