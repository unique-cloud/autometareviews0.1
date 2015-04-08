class CreateNegativeWords < ActiveRecord::Migration
  def change
    create_table :negative_words do |t|
      t.text :title
      t.timestamps
    end
  end
end
