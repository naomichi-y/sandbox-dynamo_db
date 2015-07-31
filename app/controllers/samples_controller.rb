class SamplesController < ApplicationController
  before_filter :check_exist_table, except: [:index, :create_table]

  def index
    @dynamo_db_methods = SamplesController.instance_methods(false)
    @benchmarks_methods = BenchmarksController.instance_methods(false)
  end

  def batch_write_item
    @dynamo_db.batch_write_item({
      request_items: {
       DynamoDb::TABLE_THREADS => [
         {
           put_request: {
             item: {
               id: 1000,
               thread_group_id: 1000,
               timestamp: 1437723212.765972,
               message: 'Good morning',
               client: {
                 remote_ip: '192.168.0.1',
                 browser_name: 'Chrome'
               }
             }
           }
         },
         {
           put_request: {
             item: {
               id: 1000,
               timestamp: 1437723212.765973,
               thread_group_id: 2000,
               message: 'Goodbye'
             }
           }
         },
         {
           put_request: {
             item: {
               id: 1000,
               timestamp: 1437723212.765974,
               thread_group_id: 3000,
               message: 'So long',
               client: {
                 remote_ip: '192.168.0.1',
                 browser_name: 'Firefox'
               }
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
          attribute_name: 'thread_group_id',
          attribute_type: 'N',
        },
        {
          attribute_name: 'message',
          attribute_type: 'S',
        },
      ],
      table_name: DynamoDb::TABLE_THREADS,
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
          index_name: 'index_thread_group_id',
          key_schema: [
            {
              # Required HASH type attribute - must match the table's HASH key attribute name
              attribute_name: 'id',
              key_type: 'HASH'
            },
            {
              # alternate RANGE key attribute for the secondary index
              attribute_name: 'thread_group_id',
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
          index_name: 'index_message',
          key_schema: [
            {
              attribute_name: 'message',
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

    @dynamo_db.wait_until(:table_exists, {:table_name => DynamoDb::TABLE_THREADS}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end
  end

  def describe_table
    @access_log = @dynamo_db.describe_table({table_name: DynamoDb::TABLE_THREADS})
  end

  def drop_table
    @dynamo_db.delete_table({
      table_name: DynamoDb::TABLE_THREADS
    })
    @dynamo_db.wait_until(:table_not_exists, {:table_name => DynamoDb::TABLE_THREADS}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end
  end

  def get_item
    @response = @dynamo_db.get_item({
      table_name: DynamoDb::TABLE_THREADS,
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
      table_name: DynamoDb::TABLE_THREADS,
      item: {
        id: 1000,
        timestamp: 1437723212.765971,
        thread_group_id: 2000,
        message: 'Hello',
        client: {
          remote_ip: '192.168.0.1',
          browser_name: 'Chrome'
        }
      }
    })
  end

  def scan
    @response = @dynamo_db.scan({
      table_name: DynamoDb::TABLE_THREADS
    })
  end

  def query
    @response = @dynamo_db.query({
      table_name: DynamoDb::TABLE_THREADS,

      ## Use hash search
      # key_condition_expression: 'id = :id',
      # expression_attribute_values: {
      #   ':id' => 1000,
      #   ':remote_ip' => '192.168.0.1',
      #   ':browser_name' => 'Chrome'
      # },

      ## Use hash+range search
      # key_condition_expression: 'id = :id AND #timestamp BETWEEN :timestamp',
      # expression_attribute_names: {
      #   '#timestamp' => 'timestamp'
      # },
      # expression_attribute_values: {
      #   ':id' => 1000,
      #   ':timestamp' => 1437723212.765971,
      #   ':remote_ip' => '192.168.0.1',
      #   ':browser_name' => 'Chrome'
      # },

      ## Use local secondary index
      # index_name: 'index_thread_group_id',
      # key_condition_expression: 'id = :id AND thread_group_id BETWEEN :begin_thread_group_id AND :end_thread_group_id',
      # expression_attribute_values: {
      #   ':id' => 1000,
      #   ':begin_thread_group_id' =>  1000,
      #   ':end_thread_group_id' => 3000,
      #   ':remote_ip' => '192.168.0.1',
      #   ':browser_name' => 'Chrome'
      # },

      ## Use global secondary index
      index_name: 'index_message',
      key_condition_expression: 'message = :message',
      expression_attribute_values: {
        ':message' => 'So long',
        ':remote_ip' => '192.168.0.1',
        ':browser_name' => 'Firefox'
      },

      # With filter
      filter_expression: 'client.remote_ip = :remote_ip AND client.browser_name = :browser_name',
    })
  end

  private
  def check_exist_table
    raise 'Table does not exist.' unless @dynamo_db.exist_table?(DynamoDb::TABLE_THREADS)
  end
end
