class Admin::ChartsController < ApplicationController

  before_filter :redirect_to_ssl, :check_authentication

  def revenue_history_days
    limit = 30
    query_results = revenue_history_days_results(limit)

    labels = []
    data = []

    0.upto(limit-1) {
      labels << ''
      data << 0
    }

    query_results.each {|x|
      xindex = -x['days_ago'].to_i + limit-1
      next if xindex < 0 || xindex > limit-1
      revenue = x['revenue'].to_f.round

      d = Date.strptime("#{x['month']}/#{x['day']}/#{x['year']}", '%m/%d/%Y')
      labels[xindex] = d.wday == 0 ? "#{x['month']}/#{x['day']}" : ""
      data[xindex] = revenue
    }

    g = new_chart(data, labels)

    render :text => g.render
  end

  def revenue_history_weeks
    limit = 26
    query_results = revenue_history_weeks_results(limit)

    labels = []
    data = []

    0.upto(limit-1) {
      labels << ''
      data << 0
    }

    today = Date.today

    query_results.each {|x|
      weeks_ago = today.cweek - x['week'].to_i
      xindex = -weeks_ago + limit-1
      next if xindex < 0 || xindex > limit-1
      revenue = x['revenue'].to_f.round

      labels[xindex] = x['week']
      data[xindex] = revenue
    }

    g = new_chart(data, labels)
    g.set_x_label_style(10, '#000000', 0, 2)

    render :text => g.render
  end

  def revenue_history_months
    limit = 12
    query_results = revenue_history_months_results(limit)

    labels = []
    data = []

    0.upto(limit-1) {
      labels << ''
      data << 0
    }

    query_results.each {|x|
      xindex = -x['months_ago'].to_i + limit-1
      next if xindex < 0 || xindex > limit-1
      revenue = x['revenue'].to_f.round

      labels[xindex] = "#{x['month']}/#{x['year']}"
      data[xindex] = revenue
    }

    g = new_chart(data, labels)
    g.set_x_label_style(10, '#000000', 0, 2)

    render :text => g.render
  end

  private
  def new_chart(data, labels)
    g = OpenFlashChart.new

    g.set_data(data)
    g.bar_filled(75, '#000000', '#333333', 'revenue', 10)
    g.set_bg_color('#FFFFFF')

    g.set_x_labels(labels)
    g.set_x_label_style(10, '#000000', 0, 1)
    g.set_x_axis_steps(0)

    if data.max == 0
      g.set_y_max(100)
    else
      g.set_y_max((data.max.to_f/100).ceil * 100)
    end

    g.set_y_label_steps(5)

    g.instance_variable_set :@y_axis_color, '#AAAAAA'
    g.instance_variable_set :@x_axis_color, '#666666'
    g.instance_variable_set :@y_grid_color, '#CCCCCC'
    g.instance_variable_set :@x_grid_color, '#FFFFFF'

    g.set_tool_tip('#x_label#<br>$#val#');

    return g
  end

  private
  def sqlite_date_expr(days)
      return "julianday('now', '-#{days-1} day') <= julianday(order_time)"
  end
  
  
  def revenue_history_days_sql(days)
    if Order.connection.adapter_name == 'PostgreSQL'
      "select extract(year from orders.order_time) as year,
              extract(month from orders.order_time) as month,
              extract(day from orders.order_time) as day,
              extract(day from age(date_trunc('day', orders.order_time))) as days_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              max(orders.order_time) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free' and current_date - #{days-1} <= order_time

        group by year, month, day, days_ago

        order by last_time desc"
    elsif Order.connection.adapter_name =~ /^sqlite/i
      date_expr = sqlite_date_expr(days)
      "select strftime('%Y', orders.order_time) as year,
              strftime('%m', orders.order_time) as month,
              strftime('%d', orders.order_time) as day,
              cast (
                julianday('now', 'start of day') - julianday(orders.order_time, 'start of day')
              as int) as days_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              max(orders.order_time) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free' and #{date_expr}

        group by year, month, day, days_ago

        order by last_time desc"
    else
      # Assume mysql
      "select extract(year from orders.order_time) as year,
              extract(month from orders.order_time) as month,
              extract(day from orders.order_time) as day,
              datediff(now(), orders.order_time) as days_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              max(orders.order_time) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free' and current_date - #{days-1} <= order_time

        group by year, month, day, days_ago

        order by last_time desc"
    end
  end

  def revenue_history_days_results(days)
    return Order.connection.select_all(revenue_history_days_sql(days))
  end

  def revenue_history_weeks_sql(weeks)
    if Order.connection.adapter_name =~ /^sqlite/i
      days = weeks*7
      date_expr = sqlite_date_expr(days)
      "select strftime('%W', orders.order_time) as week,
            sum(line_items.unit_price * quantity)
              - sum(coalesce(coupons.amount, 0))
              - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
            datetime(max(julianday(orders.order_time))) as last_time

       from orders
            inner join line_items on orders.id = line_items.order_id
            left outer join coupons on coupons.id = orders.coupon_id

      where status = 'C' and lower(payment_type) != 'free' and #{date_expr}

      group by week

      order by last_time desc limit #{weeks}"
    else
      "select extract(week from orders.order_time) as week,
            sum(line_items.unit_price * quantity)
              - sum(coalesce(coupons.amount, 0))
              - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
            max(orders.order_time) as last_time

       from orders
            inner join line_items on orders.id = line_items.order_id
            left outer join coupons on coupons.id = orders.coupon_id

      where status = 'C' and lower(payment_type) != 'free' and current_date - #{(weeks-1)*7} <= order_time

      group by week

      order by last_time desc limit #{weeks}"
    end
  end
  
  def revenue_history_weeks_results(weeks)
    return Order.connection.select_all(revenue_history_weeks_sql(weeks))
  end

  def revenue_history_months_sql(months)
    if Order.connection.adapter_name == 'PostgreSQL'
      "select extract(year from orders.order_time) as year,
              extract(month from orders.order_time) as month,
              extract(month from age(date_trunc('month', orders.order_time))) as months_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              max(orders.order_time) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free'

        group by year, month, months_ago

        order by last_time desc limit #{months}"
    elsif Order.connection.adapter_name =~ /^sqlite/i
      "select strftime('%Y', orders.order_time) as year,
              strftime('%m', orders.order_time) as month,
              cast(
                (julianday('now', 'start of month') - julianday(orders.order_time, 'start of month'))/30
              as int) as months_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              datetime(max(julianday(orders.order_time))) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free'
          and julianday('now', '-#{months} months') <= julianday(order_time)

        group by year, month, months_ago

        order by last_time desc limit #{months}"
    else
      # Assume mysql
      "select extract(year from orders.order_time) as year,
              extract(month from orders.order_time) as month,
              month(datediff(now(), orders.order_time)) as months_ago,
              sum(line_items.unit_price * quantity)
                - sum(coalesce(coupons.amount, 0))
                - sum(line_items.unit_price * quantity * coalesce(percentage, 0) / 100) as revenue,
              max(orders.order_time) as last_time

         from orders
              inner join line_items on orders.id = line_items.order_id
              left outer join coupons on coupons.id = orders.coupon_id

        where status = 'C' and lower(payment_type) != 'free'

        group by year, month, months_ago

        order by last_time desc limit #{months}"
    end
  end
  
  def revenue_history_months_results(months)
    return Order.connection.select_all(revenue_history_months_sql(months))
  end
end
