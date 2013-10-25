class Helu
  # Ruby wrapper class for SKProduct
  class Product
    attr_accessor :id, :title, :description, :price, :locale

    def initialize product = nil
      self.product = product if product
    end

    def product= product
      @id = product.productIdentifier
      @title = product.localizedTitle
      @description = product.localizedDescription
      @price = product.price
      @locale = product.priceLocale
    end

    def currency
      @locale.objectForKey(NSLocaleCurrencyCode)
    end

    def price_str
      nf = NSNumberFormatter.alloc.init
      nf.setFormatterBehavior(NSNumberFormatterBehavior10_4)
      nf.setNumberStyle(NSNumberFormatterCurrencyStyle)
      nf.setLocale(self.locale)
      nf.stringFromNumber(self.price)
    end
  end
end