require File.dirname(__FILE__) + '/../test_helper'
require 'admin/charts_controller'

# Re-raise errors caught by the controller.
class Admin::ChartsController; def rescue_action(e) raise e end; end

# Expose private methods for testing
class Admin::ChartsController
  def test_revenue_history_days_sql_results(days)
    return revenue_history_days_sql_results(days)
  end
end

class AdminChartsControllerTest < Test::Unit::TestCase
  fixtures :products, :orders, :line_items, :coupons

  def setup
    @controller = Admin::ChartsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_revenue_history_days_sql_results
    # 3 orders within last 30 days
    query_results = @controller.test_revenue_history_days_sql_results(30)
    assert_equal(4, query_results.length)
    
    # Match against order(:first)
    result = query_results[0]
    order_time  = orders(:first).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(0, result['days_ago'].to_i)
    
    # Match against order(:taxed)
    result = query_results[1]
    order_time  = orders(:taxed).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(0, result['days_ago'].to_i)
    
    # Match against order(:last_week)
    result = query_results[2]
    order_time  = orders(:last_week).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(5, result['days_ago'].to_i)
    
    # Match against order(:last_month)
    result = query_results[3]
    order_time  = orders(:last_month).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(15, result['days_ago'].to_i)
  end
end
