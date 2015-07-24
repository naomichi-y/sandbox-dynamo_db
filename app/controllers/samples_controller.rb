class SamplesController < ApplicationController
  before_filter :check_exist_table, except: [:index, :create_table]

  def index
    @dynamo_db_methods = SamplesController.instance_methods(false)
    @benchmarks_methods = BenchmarksController.instance_methods(false)
  end

  def batch_write_item
    @dynamo_db.batch_write_item({
      request_items: {
       DynamoDb::TABLE_TEST => [
         {
           put_request: {
             item: {
               id: 1000,
               timestamp: 1437723212.765972,
               name: 'naomichi yamakita',
               agent: {
                 browser: 'Chrome',
                 version: '43'
               }
             }
           }
         },
         {
           put_request: {
             item: {
               id: 1000,
               timestamp: 1437723212.765973,
             }
           }
         },
         {
           put_request: {
             item: {
               id: 1000,
               timestamp: 1437723212.765974,
             }
           }
         },
       ]
      }
    })
  end

  def create_table
    @dynamo_db.create_table({
      attribute_definitions: [
        {
          attribute_name: 'id',
          attribute_type: 'N',
        },
        {
          attribute_name: 'timestamp',
          attribute_type: 'N',
        },
        {
          attribute_name: 'point',
          attribute_type: 'N',
        },
        {
          attribute_name: 'gender',
          attribute_type: 'S',
        },
      ],
      table_name: DynamoDb::TABLE_TEST,
      key_schema: [
        {
          attribute_name: 'id',
          key_type: 'HASH',
        },
        {
          attribute_name: 'timestamp',
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

    @dynamo_db.wait_until(:table_exists, {:table_name => DynamoDb::TABLE_TEST}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end
  end

  def describe_table
    @access_log = @dynamo_db.describe_table({table_name: DynamoDb::TABLE_TEST})
  end

  def drop_table
    @dynamo_db.delete_table({
      table_name: DynamoDb::TABLE_TEST
    })
    @dynamo_db.wait_until(:table_not_exists, {:table_name => DynamoDb::TABLE_TEST}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end
  end

  def get_item
    @response = @dynamo_db.get_item({
      table_name: DynamoDb::TABLE_TEST,
      key: {
        id: 1000,
        timestamp: 1437723212.765971
      }
    })
  end

  def list_tables
  end

  def put_item
    @dynamo_db.put_item({
      table_name: DynamoDb::TABLE_TEST,
      item: {
        id: 1000,
        timestamp: 1437723212.765971,
        name: 'naomichi yamakita',
        gender: 'male',
        point: 2000,
        agent: {
          browser: 'Chrome',
          version: '43'
        }
      }
    })
  end

  def scan
    @response = @dynamo_db.scan({
      table_name: DynamoDb::TABLE_TEST
    })
  end

  def query
    @response = @dynamo_db.query({
      table_name: DynamoDb::TABLE_TEST,

      ## Use hash search
      key_condition_expression: 'id = :id',
      expression_attribute_names: {
        '#name' => 'name',
        '#agent' => 'agent'
      },
      expression_attribute_values: {
        ':id' => 1000,
        ':name' => 'naomichi',
        ':browser' => 'Chrome'
      },

      ## Use hash+range search
      # key_condition_expression: 'id = :id AND begins_with(#timestamp, :timestamp)',
      # expression_attribute_names: {
      #   '#timestamp' => 'timestamp',
      #   '#name' => 'name',
      #   '#agent' => 'agent'
      # },
      # expression_attribute_values: {
      #   ':id' => 1000,
      #   ':name' =>'naomichi',
      #   ':timestamp' => '2015',
      #   ':browser' => 'Chrome'
      # },

      ## Use local secondary index
      # index_name: 'index_point',
      # key_condition_expression: 'id = :id AND point BETWEEN :begin_point AND :end_point',
      # expression_attribute_names: {
      #   '#name' => 'name',
      #   '#agent' => 'agent'
      # },
      # expression_attribute_values: {
      #   ':id' => 1000,
      #   ':name' =>'naomichi',
      #   ':begin_point' =>  1000,
      #   ':end_point' => 3000,
      #   ':browser' => 'Chrome'
      # },

      ## Use global secondary index
      # index_name: 'index_gender',
      # key_condition_expression: 'gender = :gender',
      # expression_attribute_names: {
      #   '#name' => 'name',
      #   '#agent' => 'agent'
      # },
      # expression_attribute_values: {
      #   ':name' =>'naomichi',
      #   ':gender' => 'male',
      #   ':browser' => 'Chrome'
      # },

      # With filter
      filter_expression: 'contains(#name, :name) AND #agent.browser = :browser',
    })
  end

  private
  def check_exist_table
    raise 'Table does not exist.' unless @dynamo_db.exist_table?(DynamoDb::TABLE_TEST)
  end
end
