class DynamoDbController < ApplicationController
  def index
    @methods = DynamoDbController.instance_methods(false)
  end

  def create_table
    @dynamo_db.create_table({
      attribute_definitions: [
        {
          attribute_name: 'id',
          attribute_type: 'S',
        },
        {
          attribute_name: 'date',
          attribute_type: 'S',
        },
      ],
      table_name: 'sandbox-access_logs',
      key_schema: [
        {
          attribute_name: 'id',
          key_type: 'HASH',
        },
        {
          attribute_name: 'date',
          key_type: 'RANGE'
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1,
      }
    })
  end

  def describe_table
    @access_log = @dynamo_db.describe_table({table_name: 'sandbox-access_logs'})
  end

  def drop_table
    @dynamo_db.delete_table({
      table_name: 'sandbox-access_logs'
    })
  end

  def get_item
    @response = @dynamo_db.get_item({
      table_name: 'sandbox-access_logs',
      key: {
        id: '1002',
        date: '20150722'
      }
    })
  end

  def list_tables
  end

  def put_item
    @dynamo_db.put_item({
      table_name: 'sandbox-access_logs',
      item: {
        id: '1003',
        date: '20150724',
        user_name: 'naomichi yamakita',
        gender: 'male'
      }
    })
  end

  def scan
    @response = @dynamo_db.scan({
      table_name: 'sandbox-access_logs'
    })
  end

  def query
    @response = @dynamo_db.query({
      table_name: 'sandbox-access_logs',
      key_conditions: {
        id: {
          attribute_value_list: ['1003'],
          comparison_operator: 'EQ'
        },
        date: {
          attribute_value_list: ['20150722', '20150723'],
          comparison_operator: 'BETWEEN'
        }
      },
      query_filter: {
        user_name: {
          attribute_value_list: ['taro'],
          comparison_operator: 'CONTAINS'
        }
      }
    })
  end
end
