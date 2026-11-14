class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :tax_code, null: false
      t.string :email
      t.string :phone
      t.boolean :active, null: false, default: true

      t.timestamps

      t.check_constraint "CHAR_LENGTH(tax_code) = 16", name: "members_tax_code_length"
    end
    add_index :members, :tax_code, unique: true
    add_index :members, :email, unique: true
  end
end
