class CreateUsersTercs < ActiveRecord::Migration
  def self.up
    create_table :users_tercs do |t|
      t.string :firstname
      t.string :lastname
      t.boolean :gender
    end
  end
  def self.down
	drop_table:users_tercs
  end
end
