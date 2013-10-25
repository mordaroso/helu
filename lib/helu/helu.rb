class Helu

  attr_accessor :storage, :winning, :restore, :fail

  SKPaymentTransactionStateFailed
  SKPaymentTransactionStatePurchasing
  SKPaymentTransactionStatePurchased
  SKPaymentTransactionStateRestored
  SKErrorPaymentCancelled

  class <<self
    # see product_info_fetcher.rb for info
    def fetch_product_info(*products, &b)
      ProductInfoFetcher.fetch(*products, &b)
    end
  end

  def initialize
    SKPaymentQueue.defaultQueue.addTransactionObserver(self)
    @storage = LocalStorage.new
  end

  def buy(product_id)
    payment = SKPayment.paymentWithProductIdentifier(product_id)
    SKPaymentQueue.defaultQueue.addPayment(payment)
  end

  def restore
    SKPaymentQueue.defaultQueue.restoreCompletedTransactions
  end

  def close
    SKPaymentQueue.defaultQueue.removeTransactionObserver(self)
  end

#  private

  def finishTransaction(sktransaction)
    SKPaymentQueue.defaultQueue.finishTransaction(sktransaction)
    transaction = Transaction.new(sktransaction)
    if transaction.success?
      @winning.call(transaction) if @winning
      storage.add(transaction.payment.product_id)
    else
      @fail.call(transaction) if @fail
    end
  end

  def completeTransaction(sktransaction)
    finishTransaction(sktransaction)
  end

  def restoreTransaction(sktransaction)
    finishTransaction(sktransaction)
  end

  def failedTransaction(sktransaction)
    if (sktransaction.error.code != SKErrorPaymentCancelled)
      finishTransaction(sktransaction)
    elsif sktransaction.error.code == SKErrorPaymentCancelled
      transaction = Transaction.new(sktransaction)
      @fail.call(transaction) if @fail
      SKPaymentQueue.defaultQueue.finishTransaction(sktransaction)
    end
  end

  def paymentQueue(queue, updatedTransactions:transactions)

    transactions.each do |sktransaction|
      #App.alert "trx #{sktransaction.transactionState}"
      case sktransaction.transactionState
      when SKPaymentTransactionStatePurchased
        completeTransaction(sktransaction)
      when SKPaymentTransactionStateFailed
        failedTransaction(sktransaction)
      when SKPaymentTransactionStateRestored
        restoreTransaction(sktransaction)
      end
    end
  end

  def paymentQueueRestoreCompletedTransactionsFinished(queue)
    transactions = queue.transactions.map do |sktransaction|
      transaction = Transaction.new sktransaction
    end
    @restore.call transactions if @restore
  end

  class LocalStorage

    def clean
      defaults.setObject(nil, forKey: key_for_defaults)
      defaults.synchronize
    end

    def add(product_id)
      if all
        defaults.setObject([all, product_id].flatten, forKey: key_for_defaults)
      else
        defaults.setObject([product_id], forKey: key_for_defaults)
      end

      defaults.synchronize
    end

    def all
      return [] if defaults.valueForKey(key_for_defaults) == nil
      defaults.valueForKey(key_for_defaults)
    end

    private

    def key_for_defaults
      "helu_products"
    end

    def defaults
      NSUserDefaults.standardUserDefaults
    end

  end

end

