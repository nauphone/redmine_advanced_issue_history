class RemoveIsSystemNoteFromJournal < ActiveRecord::Migration
  def self.up
    Journal.where(:is_system_note => true).where("notes != ''").each do |journal|
      journal_details = journal.details.new
      journal_details.property = 'system'
      journal_details.prop_key = 'system'
      journal_details.value = journal.notes
      journal_details.save!
      journal.notes = ''
      journal.save!
    end
    remove_column :journals, :is_system_note
  end

  def self.down
    add_column :journals, :is_system_note, :boolean
    JournalDetail.where(:property => 'system').to_a.each do |journal_detail|
      journal = journal_detail.journal
      journal.notes = journal_detail.value
      journal.save!
      journal_detail.delete
    end
  end
end
