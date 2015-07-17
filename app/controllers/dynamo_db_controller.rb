class DynamoDbController < ApplicationController
  def index
  end

  def create_table
    @dynamodb.create_table({
      attribute_definitions: [
        {
          attribute_name: 'id',
          attribute_type: 'S',
        },
      ],
      table_name: 'sandbox-access_logs',
      key_schema: [
        {
          attribute_name: 'id',
          key_type: 'HASH',
        },
      ],
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1,
      }
    })

    render :nothing => true
  end

  def put_item
    @dynamodb.put_item({
      table_name: 'sandbox-access_logs',
      item: {
        'id' => 'test3'
      }
    })

    render :nothing => true
  end

  def describe_table
    @access_log = @dynamodb.describe_table({table_name: 'sandbox-access_logs'})
  end

  def list_tables
  end

  def drop_table
    @dynamodb.delete_table({
      table_name: 'sandbox-access_logs'
    })

    render :nothing => true
  end
end
