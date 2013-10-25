class Helu
  # Ruby wrapper class for SKPaymentTransaction
  class Transaction
    attr_accessor :id, :error, :payment, :state, :date, :receipt, :original_transaction

    def initialize transaction = nil
      self.transaction = transaction if transaction
    end

    def transaction= transaction
      @id = transaction.transactionIdentifier
      @date = Time.at(transaction.transactionDate) if transaction.transactionDate
      @payment = Payment.new transaction.payment
      @receipt = transaction.transactionReceipt
      @error = transaction.error
      @original_transaction = Transaction.new(transaction.originalTransaction) if transaction.originalTransaction
      self.state = transaction.transactionState
    end

    def receipt_data
      [@receipt.to_s].pack('m').gsub(/\n/, '')
    end

    def success?
      state != SKPaymentTransactionStateFailed && self.error.nil?
    end

    def state= state
      @state = state
      if state.is_a? Integer
        @state = case state
        when SKPaymentTransactionStatePurchasing
          :purchasing
        when SKPaymentTransactionStatePurchased
          :purchased
        when SKPaymentTransactionStateFailed
          :failed
        when SKPaymentTransactionStateRestored
          :restored
        else
          nil
        end
      end

    end
  end
end