require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < Test::Unit::TestCase
  fixtures :orders, :line_items, :products

  def setup
    @order = orders(:first)
  end

  def test_status_description
    @dummy = Order.new
    {"P" => "Pending",
     "C" => "Complete",
     "F" => "Failed",
     "X" => "Cancelled"}.each do |abbrev, description|
      @dummy.status = abbrev
    assert_equal(@dummy.status_description , description)
    end
  end

  def test_create_order


  end
  
  def test_licensee_name_collapses_spaces
    order = Order.new
    order.licensee_name = "Joe  Schmoe"
    assert_equal(order.licensee_name, "Joe Schmoe")
  end
  
  def test_licensee_name_strips_spaces
    order = Order.new
    order.licensee_name = "  Joe Schmoe  "
    assert_equal(order.licensee_name, "Joe Schmoe")
  end
  
  def test_licensee_name_translates_newline_to_space
    order = Order.new
    order.licensee_name = "Joe\nSchmoe"
    assert_equal(order.licensee_name, "Joe Schmoe")
  end
  
  def test_licensee_name_translates_cr_to_space
    order = Order.new
    order.licensee_name = "Joe\rSchmoe"
    assert_equal(order.licensee_name, "Joe Schmoe")
  end
  
  def test_licensee_name_translates_tab_to_space
    order = Order.new
    order.licensee_name = "Joe\tSchmoe"
    assert_equal(order.licensee_name, "Joe Schmoe")
  end
  
  def test_licensee_name_with_multiple_whitespace
    order = Order.new
    order.licensee_name = "  Joe \n \tSchmoe\r "
    assert_equal(order.licensee_name, "Joe Schmoe")
  end

end
