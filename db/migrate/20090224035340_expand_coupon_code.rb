class ExpandCouponCode < ActiveRecord::Migration
  def self.up
    change_column('coupons', 'code', :string, :limit=>64)
  end

  def self.down
    change_column('coupons', 'code', :string, :limit=>16)
  end
end
