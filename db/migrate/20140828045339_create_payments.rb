class CreatePayments < ActiveRecord::Migration
  def change
    create_table Fe::Payment.table_name do |t|
      t.timestamps
      t.integer  "application_id"
      t.string   "payment_type"
      t.string   "amount"
      t.string   "payment_account_no"
      t.string   "auth_code"
      t.string   "status"
    end
  end
end
