class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :book_copy, null: false, foreign_key: { on_delete: :restrict }
      t.references :member, null: false, foreign_key: { on_delete: :restrict }
      t.date :started_on, null: false
      t.date :due_on, null: false
      t.date :returned_on

      t.timestamps

      t.check_constraint "due_on >= started_on", name: "loans_due_after_start"
      t.check_constraint "returned_on >= started_on", name: "loans_returned_after_start"
    end
    # Aggiunta dell'indice parziale che si basa sul valore della colonna returned_on
    add_index :loans, :book_copy_id, unique: true,
              where: "returned_on IS NULL",
              name: "index_loans_one_active_per_copy"
  end
end
