class CreateBookCopies < ActiveRecord::Migration[8.1]
  def change
    create_table :book_copies do |t|
      t.string :inventory_code, null: false
      t.string :location, null: false
      t.references :book, null: false, foreign_key: { on_delete: :restrict }

      t.timestamps
    end
    add_index :book_copies, :inventory_code, unique: true
  end
end
