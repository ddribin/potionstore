require File.dirname(__FILE__) + '/../test_helper'
require 'admin/charts_controller'

# Re-raise errors caught by the controller.
class Admin::ChartsController; def rescue_action(e) raise e end; end

# Expose private methods for testing
class Admin::ChartsController
  def test_revenue_history_days_results(days)
    return revenue_history_days_results(days)
  end
  
  def test_revenue_history_weeks_results(weeks)
    return revenue_history_weeks_results(weeks)
  end
  
  def test_revenue_history_months_results(months)
    return revenue_history_months_results(months)
  end
end

class AdminChartsControllerTest < Test::Unit::TestCase
  fixtures :products, :orders, :line_items, :coupons

  def setup
    @controller = Admin::ChartsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_revenue_history_days_results
    # 3 days with orders within last 30 days
    query_results = @controller.test_revenue_history_days_results(30)
    assert_equal(3, query_results.length)
    
    # First result is for :first and :taxed (they are on the same day)
    result = query_results[0]
    order_time  = orders(:first).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(0, result['days_ago'].to_i)
    assert_equal("200", result['revenue'])
    
    # Next match contains order(:last_week)
    result = query_results[1]
    order_time  = orders(:last_week).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(5, result['days_ago'].to_i)
    assert_equal("100", result['revenue'])
    
    # Match against order(:last_month)
    result = query_results[2]
    order_time  = orders(:last_month).order_time
    assert_equal(order_time.strftime('%Y'), result['year'])
    assert_equal(order_time.strftime('%m'), result['month'])
    assert_equal(order_time.strftime('%d'), result['day'])
    assert_equal(15, result['days_ago'].to_i)
    assert_equal("100", result['revenue'])
  end
  
  def test_revenue_history_days
    @request.session[:logged_in] = true
    get :revenue_history_days
    assert_response :success
  end
  
  def test_revenue_history_weeks_results
    query_results = @controller.test_revenue_history_weeks_results(26)
    # 3 weeks within last 26 weeks have orders
    assert_equal(3, query_results.length)
    
    # Two in the last week
    result = query_results[0]
    assert_equal("200", result['revenue'])
  end

  def test_revenue_history_weeks
    @request.session[:logged_in] = true
    get :revenue_history_weeks
    assert_response :success
  end

  
  def test_revenue_history_months_results
    query_results = @controller.test_revenue_history_months_results(12)
    # It's kinda hard to test the results due to fixture orders relative
    # to first of the month.  Just make sure the results aren't empty
    assert(query_results.length > 0)
  end

  def test_revenue_history_months
    @request.session[:logged_in] = true
    get :revenue_history_months
    assert_response :success
  end
end
