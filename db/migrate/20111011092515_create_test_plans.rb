class CreateTestPlans < ActiveRecord::Migration
  def self.up
    create_table :impasse_test_plans do |t|
      t.column :version_id, :integer, :null => false
      t.column :name, :string, :null => false
      t.column :notes, :text
      t.column :active, :boolean
    end
  end

  def self.down
    drop_table :impasse_test_plans
  end
end
