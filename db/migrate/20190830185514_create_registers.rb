class CreateRegisters < ActiveRecord::Migration[6.0]
  def change
    create_table :registers do |t|
      t.integer :type_id
      t.string :num_id
      t.string :names
      t.string :lastnames
      t.string :tel_num
      t.string :email

      t.timestamps
    end
  end
end
