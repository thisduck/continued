class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.references :project
      t.string :state
      t.string :state
      t.string :output
      t.string :last_sha
      t.string :sha
      t.datetime :started_at
      t.datetime :ended_at
      t.text :logs
      t.string :diff
      t.boolean :forced

      t.timestamps
    end
  end
end
