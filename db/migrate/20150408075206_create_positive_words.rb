class CreatePositiveWords < ActiveRecord::Migration
  def change
    create_table :positive_words do |t|
      t.text :title

      t.timestamps
    end
  end
end
