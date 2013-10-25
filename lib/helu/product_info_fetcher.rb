=begin
# Sample use:
## Asynchronous, raw:
inapps = %w[first second third]
@x = Helu::ProductInfoFetcher.new(inapps) do |pi|
  p pi
end

## Asynchronous, wrapped in method call:
Helu::ProductInfoFetcher.fetch(inapps) do |pi|
  p pi
end

## Synchronous:
pi = Helu::ProductInfoFetcher.fetch(inapps)
p pi


# All three calls return an array of Helu::Products
=end
class Helu
  class ProductInfoFetcher
    @@mutex = Mutex.new
    @@cache = []

    def initialize(*products, &block)
      raise LocalJumpError, "block expected" if block.nil?
      @callback = block
      products = products.flatten

      # all cached? skip the call...
      if (@@cache.map(&:id) & products).sort == products.sort
        @callback.call(@@cache)
      else
        @sr = SKProductsRequest.alloc.initWithProductIdentifiers(products)
        @sr.delegate = self
        @sr.start
      end

      self
    end

    def productsRequest(request, didReceiveResponse: response)
      if response.nil?
        @callback.call(nil)
      else
        products = response.products.map { |prod| Product.new(prod) }
        @@mutex.synchronize { @@cache = products }
        @callback.call(products)
      end
    end

    private

    class <<self
      # make a sync call out of an async one
      def call_synchronized(method, *args)
        finished = false
        result = nil
        send(method, *args) do |res|
          result = res
          finished = true
        end
        sleep 0.1 until finished
        result
      end

      def fetch(*products, &block)
        products.flatten!
        if block.nil?
          call_synchronized(:fetch, *products)
        else
          new(*products, &block)
        end
      end

      def clear_cache
        @@mutex.synchronize { @@cache = [] }
      end
    end

  end
end
