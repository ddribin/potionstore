require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :products, :orders, :line_items, :coupons

  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_with_no_password
    get :index
    assert_redirected_to 'admin/login'
    assert_equal(session[:intended_url] , '/admin')
  end

  def test_login_with_faulty_password
    post :login, {:username => 'joeblow', :password => 'totallyfakingit'}
    assert_template 'login'
    assert_response :success
  end

  def test_login_with_good_password
    post :login, {
       :username => $STORE_PREFS['admin_username'],
       :password => $STORE_PREFS['admin_password']}

    assert_redirected_to :action => 'index'
  end

  def generate_coupons_blank
    process 'generate_coupons', {}, { :logged_in => true }
    assert_response :success
    assert_template 'generate_coupons'
  end
  
  def test_index_assigns
    @request.session[:logged_in] = true
    get :index
    assert_equal(assigns(:num_orders).length, 4)
    assert_equal(assigns(:revenue).length, 4)
    
    # Within 1 day
    num_orders = assigns(:num_orders)[0]
    revenue = assigns(:revenue)[0]
    assert_equal("2", num_orders)
    assert_equal(200, revenue)
    
    # With 7 days
    num_orders = assigns(:num_orders)[1]
    revenue = assigns(:revenue)[1]
    assert_equal("3", num_orders)
    assert_equal(300, revenue)
    
    # With 30 days
    num_orders = assigns(:num_orders)[2]
    revenue = assigns(:revenue)[2]
    assert_equal("4", num_orders)
    assert_equal(400, revenue)
    
    # With 365 days
    num_orders = assigns(:num_orders)[3]
    revenue = assigns(:revenue)[3]
    assert_equal("5", num_orders)
    assert_equal(500, revenue)
    
    daily_avg = 400.0/90.0
    assert_in_delta(daily_avg * 365, assigns(:year_estimate), 0.01)
    # Don't bother testing month_estimate, as it uses the dame daily_avg
    # value, which is really the important thing to test.
  end
end
