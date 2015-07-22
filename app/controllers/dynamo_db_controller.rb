class DynamoDbController < ApplicationController
  LOG_TABLE = 'sandbox-access_logs'

  before_filter :check_exist_table, except: [:index, :create_table]

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
          attribute_name: 'point',
          attribute_type: 'N',
        },
        {
          attribute_name: 'gender',
          attribute_type: 'S',
        },
        {
          attribute_name: 'created_at',
          attribute_type: 'S',
        },
      ],
      table_name: LOG_TABLE,
      key_schema: [
        {
          attribute_name: 'id',
          key_type: 'HASH',
        },
        {
          attribute_name: 'created_at',
          key_type: 'RANGE'
        }
      ],
      local_secondary_indexes: [
        {
          index_name: 'index_point',
          key_schema: [
            {
              # Required HASH type attribute - must match the table's HASH key attribute name
              attribute_name: 'id',
              key_type: 'HASH'
            },
            {
              # alternate RANGE key attribute for the secondary index
              attribute_name: 'point',
              key_type: 'RANGE'
            }
          ],
          projection: {
            projection_type: 'ALL',
          }
        }
      ],
      global_secondary_indexes: [
        {
          index_name: 'index_gender',
          key_schema: [
            {
              attribute_name: 'gender',
              key_type: 'HASH'
            }
          ],
          projection: {
            projection_type: 'ALL',
          },
          provisioned_throughput: {
            read_capacity_units: 1,
            write_capacity_units: 1
          }
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1,
      }
    })
  end

  def describe_table
    @access_log = @dynamo_db.describe_table({table_name: LOG_TABLE})
  end

  def drop_table
    @dynamo_db.delete_table({
      table_name: LOG_TABLE
    })
  end

  def get_item
    @response = @dynamo_db.get_item({
      table_name: LOG_TABLE,
      key: {
        id: '1003',
        created_at: '20150724'
      }
    })
  end

  def list_tables
  end

  def put_item
    @dynamo_db.put_item({
      table_name: LOG_TABLE,
      item: {
        id: '1003',
        user_name: 'naomichi yamakita',
        gender: 'male',
        point: 2000,
        created_at: '20150724'
      }
    })
  end

  def scan
    @response = @dynamo_db.scan({
      table_name: LOG_TABLE
    })
  end

  def query
    @response = @dynamo_db.query({
      table_name: LOG_TABLE,

      ## Use hash
      # key_condition_expression: 'id = :id',
      # expression_attribute_values: {
      #   ':id' => '1003',
      #   ':user_name' =>'naomichi',
      # },

      ## Use hash
      key_condition_expression: 'id = :id AND created_at = :created_at',
      expression_attribute_values: {
        ':id' => '1003',
        ':user_name' =>'naomichi',
        ':created_at' => '20150724'
      },

      ## Use global secondary index
      # index_name: 'index_point',
      # key_condition_expression: 'id = :id AND point BETWEEN :begin_point AND :end_point',
      # expression_attribute_values: {
      #   ':id' => '1003',
      #   ':user_name' =>'naomichi',
      #   ':begin_point' =>  1000,
      #   ':end_point' => 3000
      # },

      ## Use local secondary index
      # index_name: 'index_gender',
      # key_condition_expression: 'gender = :gender',
      # expression_attribute_values: {
      #   ':user_name' =>'naomichi',
      #   ':gender' => 'male',
      # },

      # With filter
      filter_expression: 'contains(user_name, :user_name)',
    })
  end

  private
  def check_exist_table
    resource = Aws::DynamoDB::Resource.new(client: @dynamo_db)
    raise 'Table does not exist.' unless resource.table(LOG_TABLE).present?
  end
end
