module Aws
  module Record

    # Usage of {Aws::Record} requires only that you include this module. This
    # method will then pull in the other default modules.
    #
    # @example
    #   class MyTable
    #     include Aws::Record
    #     # Attribute definitions go here...
    #   end
    def self.included(sub_class)
      sub_class.extend(RecordClassMethods)
      sub_class.include(Attributes)
      sub_class.include(ItemOperations)
    end

    private
    def dynamodb_client
      self.class.dynamodb_client
    end

    module RecordClassMethods

      # Returns the Amazon DynamoDB table name for this model class.
      #
      # By default, this will simply be the name of the class. However, you can
      # also define a custom table name at the class level to be anything that
      # you want.
      #
      # @example
      #   class MyTable
      #     include Aws::Record
      #   end
      #   
      #   class MyTableTest
      #     include Aws::Record
      #     set_table_name "test_MyTable"
      #   end
      #   
      #   MyTable.table_name      # => "MyTable"
      #   MyOtherTable.table_name # => "test_MyTable"
      def table_name
        if @table_name
          @table_name
        else
          @table_name = self.name
        end
      end

      # Allows you to set a custom Amazon DynamoDB table name for this model
      # class.
      #
      # @example
      #   class MyTable
      #     include Aws::Record
      #     set_table_name "prod_MyTable"
      #   end
      #   
      #   class MyTableTest
      #     include Aws::Record
      #     set_table_name "test_MyTable"
      #   end
      #   
      #   MyTable.table_name      # => "prod_MyTable"
      #   MyOtherTable.table_name # => "test_MyTable"
      def set_table_name(name)
        @table_name = name
      end

      # Fetches the table's provisioned throughput from the associated Amazon
      # DynamoDB table.
      #
      # @return [Hash] a hash containing the +:read_capacity_units+ and
      #   +:write_capacity_units+ of your remote table.
      # @raise [Aws::Record::Errors::TableDoesNotExist] if the table name does
      #   not exist in DynamoDB.
      def provisioned_throughput
        begin
          resp = dynamodb_client.describe_table(table_name: @table_name)
          throughput = resp.table.provisioned_throughput
          return {
            read_capacity_units: throughput.read_capacity_units,
            write_capacity_units: throughput.write_capacity_units
          }
        rescue DynamoDB::Errors::ResourceNotFoundException
          raise Record::Errors::TableDoesNotExist
        end
      end

      # Checks if the model's table name exists in Amazon DynamoDB.
      #
      # @return [Boolean] true if the table does exist, false if it does not.
      def table_exists?
        begin
          resp = dynamodb_client.describe_table(table_name: @table_name)
          if resp.table.table_status == "ACTIVE"
            true
          else
            false
          end
        rescue DynamoDB::Errors::ResourceNotFoundException
          false
        end
      end

      # Configures the Amazon DynamoDB client used by this class and all
      # instances of this class.
      #
      # Please note that this method is also called internally when you first
      # attempt to perform an operation against the remote end, if you have not
      # already configured a client. As such, please read and understand the
      # documentation in the AWS SDK for Ruby V2 around
      # {http://docs.aws.amazon.com/sdkforruby/api/index.html#Configuration configuration}
      # to ensure you understand how default configuration behavior works. When
      # in doubt, call this method to ensure your client is configured the way
      # you want it to be configured.
      #
      # @param [Hash] opts the options you wish to use to create the client.
      #  Note that if you include the option +:client+, all other options
      #  will be ignored. See the documentation for other options in the
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#initialize-instance_method AWS SDK for Ruby V2}.
      # @option opts [Aws::DynamoDB::Client] :client allows you to pass in your
      #  own pre-configured client.
      def configure_client(opts = {})
        provided_client = opts.delete(:client)
        opts[:user_agent_suffix] = user_agent(opts.delete(:user_agent_suffix))
        client = provided_client || Aws::DynamoDB::Client.new(opts)
        @dynamodb_client = client
      end

      # Gets the
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html Aws::DynamoDB::Client}
      # instance that this model uses. When called for the first time, if
      # {#configure_client} has not yet been called, will configure a new client
      # for you with default parameters.
      #
      # @return [Aws::DynamoDB::Client] the Amazon DynamoDB client instance.
      def dynamodb_client
        @dynamodb_client ||= configure_client
      end
    end
  end
end