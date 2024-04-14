class DeleteUser < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :password, :string
    remove_column :users, :reputation_points, :float
    remove_column :users, :moderated, :integer
    remove_column :users, :email, :string
    remove_column :users, :joined_date, :float
  end
end
