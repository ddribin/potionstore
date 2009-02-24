class Coupon < ActiveRecord::Base
  def initialize
    super()
    self.coupon = random_string_of_length(16).upcase
    self.used_count = 0
    self.use_limit = 1
  end

  def before_create
    self.creation_time ||= Time.now
  end

  def expired?
    expired_use_count = ((self.use_limit != 0) && (self.used_count >= self.use_limit))
    expired_day_count = ((self.numdays != 0) && (self.creation_time + self.numdays.days < Time.now))
    expired = (expired_use_count || expired_day_count)
    return expired
  end

  private
  def random_string_of_length(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    s = ""
    1.upto(len) { |i| s << chars[rand(chars.size-1)] }
    return s
  end

end
