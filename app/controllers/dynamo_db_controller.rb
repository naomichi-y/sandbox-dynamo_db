class DynamoDbController < ApplicationController
  def index
  end

  def create_table
    @dynamo_db.create_table({
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
    @dynamo_db.put_item({
      table_name: 'sandbox-access_logs',
      item: {
        'id' => '1002'
      }
    })

    render :nothing => true
  end

  def describe_table
    @access_log = @dynamo_db.describe_table({table_name: 'sandbox-access_logs'})
  end

  def list_tables
  end

  def drop_table
    @dynamo_db.delete_table({
      table_name: 'sandbox-access_logs'
    })

    render :nothing => true
  end
end
