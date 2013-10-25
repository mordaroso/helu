class Helu
  class Payment
    attr_accessor :product_id, :quantity, :data, :username

    def initialize payment = nil
      self.payment = payment if payment
    end

    def payment= payment
      @product_id = payment.productIdentifier
      @data = payment.requestData
      @quantity = payment.quantity
    end
  end
end