class CreateExecutionBugs < ActiveRecord::Migration
  def self.up
    create_table :impasse_execution_bugs do |t|
      t.column :execution_id, :integer
      t.column :bug_id, :integer
    end
  end

  def self.down
    drop_table :impasse_execution_bugs
  end
end
