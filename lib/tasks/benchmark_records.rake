namespace :benchmark_records do
  desc 'create benchmark table/records'
  task :setup => :environment do
    Rake::Task['benchmark_records:drop'].invoke
    Rake::Task['benchmark_records:create'].invoke
    Rake::Task['benchmark_records:generate'].invoke
  end

  desc 'drop benchmark table'
  task :drop => :environment do
    dynamo_db = DynamoDb.new.connect

    if dynamo_db.exist_table?(DynamoDb::TABLE_BENCHMARK_THREADS)
      dynamo_db.delete_table({
        table_name: DynamoDb::TABLE_BENCHMARK_THREADS,
      })
      dynamo_db.wait_until(:table_not_exists, {:table_name => DynamoDb::TABLE_BENCHMARK_THREADS}) do |w|
        w.delay = 3
        w.max_attempts = 5
      end
    end

    puts 'Drop table.'
  end

  desc 'create benchmark table'
  task :create => :environment do
    dynamo_db = DynamoDb.new.connect
    dynamo_db.create_table({
      attribute_definitions: [
        {
          attribute_name: 'id',
          attribute_type: 'S',
        },
        {
          attribute_name: 'timestamp',
          attribute_type: 'N',
        },
        {
          attribute_name: 'thread_group_id',
          attribute_type: 'N',
        }
      ],
      table_name: DynamoDb::TABLE_BENCHMARK_THREADS,
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
      global_secondary_indexes: [
        {
          index_name: 'index_thread_group_id',
          key_schema: [
            {
              attribute_name: 'thread_group_id',
              key_type: 'HASH'
            }
          ],
          projection: {
            projection_type: 'ALL',
          },
          provisioned_throughput: {
            read_capacity_units: 10,
            write_capacity_units: 10
          }
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 15,
        write_capacity_units: 15,
      }
    })
    dynamo_db.wait_until(:table_exists, {:table_name => DynamoDb::TABLE_BENCHMARK_THREADS}) do |w|
      w.delay = 3
      w.max_attempts = 5
    end

    puts 'Created table.'
  end

  desc 'create benchmark records'
  task :generate => :environment do
    dynamo_db = DynamoDb.new.connect

    id = 1
    batch_limit = 25
    created_count = 0
    max_count = 1000

    execute_time = Benchmark.realtime do
      while max_count > created_count
        items = []

        if max_count - created_count < batch_limit
          batch_limit = max_count - created_count
        end

        batch_limit.times do
          items << {
            put_request: {
              item: {
                id: [*1..9, *'A'..'Z', *'a'..'z'].sample(16).join,
                timestamp: Time.now.getutc.to_f,
                thread_group_id: rand(1..9),
                subject: [*1..9, *'A'..'Z', *'a'..'z'].sample(16).join,
                message: [*1..9, *'A'..'Z', *'a'..'z'].sample(48).join
              }
            }
          }

          id += 1
        end

        # If an exception does not occur
        response = dynamo_db.batch_write_item({
          request_items: {
           DynamoDb::TABLE_BENCHMARK_THREADS => items
          }
        })

        if response.unprocessed_items.count > 0
          wait = 0.2

          begin
            puts "Write failure! (retry wait #{wait}sec)"

            sleep(wait)
            response = dynamo_db.batch_write_item({
              request_items: {
               DynamoDb::TABLE_BENCHMARK_THREADS => items
              }
            })

            wait = wait * 2
          end while response.unprocessed_items.count > 0
        end

        created_count += batch_limit
        puts "generate #{created_count} records"
      end
    end

    puts "#{max_count} record registered. [#{execute_time}sec]"
  end
end
