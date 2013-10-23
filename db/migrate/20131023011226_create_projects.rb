class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :repository_url
      t.string :branch
      t.string :last_sha

      t.timestamps
    end
  end
end
