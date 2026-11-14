class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :isbn, null: false
      t.integer :publication_year, null: false
      t.string :category, null: false
      t.string :author, null: false

      t.timestamps

      t.check_constraint "publication_year > 0", name: "books_publication_year_positive"
    end
    add_index :books, :isbn, unique: true
  end
end
