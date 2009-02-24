require File.dirname(__FILE__) + '/../test_helper'

class CouponTest < Test::Unit::TestCase
  fixtures :coupons
  
  def new_coupon
    coupon = Coupon.new
    coupon.code = "Coupon Code"
    coupon.product_code = "TEST1"
    coupon.coupon = "Test 1"
    coupon.description = "Coupon Description"
    coupon.amount = 5
    coupon.save()
    return coupon
  end

  def test_creation_state
    coupon = new_coupon
    
    assert_equal(coupon.used_count, 0)
    assert_equal(coupon.use_limit, 1)
    assert(!coupon.expired?)
  end
  
  def test_expired_used_count
    coupon = new_coupon
    
    coupon.used_count += 1
    
    assert(coupon.expired?)
  end
  
  def test_zero_use_limit_ignored_for_use_count
    coupon = new_coupon
    coupon.use_limit = 0
    
    coupon.used_count += 1
    
    assert(!coupon.expired?)
  end
  
  def test_numdays_not_expired
    coupon = new_coupon
    coupon.numdays = 1
    
    assert(!coupon.expired?)
  end
  
  def test_numdays_expired
    coupon = new_coupon
    coupon.creation_time = 2.days.ago
    coupon.numdays = 1
    
    assert(coupon.expired?)
  end
  
  def test_used_count_trumps_numdays
    coupon = new_coupon
    coupon.numdays = 1
    
    coupon.used_count += 1
    
    assert(coupon.expired?)
  end
  
  def test_zero_use_limit_ignored_with_numdays
    coupon = new_coupon
    coupon.use_limit = 0
    coupon.creation_time = 1.days.ago
    coupon.numdays = 2
    
    coupon.used_count += 1
    
    assert(!coupon.expired?)
  end
end
