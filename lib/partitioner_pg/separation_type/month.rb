module PartitionerPg
  module SeparationType
    module Month
      def create_next_month_table
        create_month_table(Date.today.next_month)
      end

      def drop_old_month_table
        drop_month_table(Date.today.prev_month.prev_month)
      end

      def create_month_table(date=Date.today)
        date_start = date.at_beginning_of_month
        date_end = date.at_beginning_of_month.next_month
        partition_table_name = name_of_partition_table(date)
        sql = "CREATE TABLE IF NOT EXISTS #{partition_table_name} (
               CHECK ( #{parting_column} >= DATE('#{date_start}') AND #{parting_column} < DATE('#{date_end}') )
               ) INHERITS (#{table_name});"
        execute_sql(sql)
        sql = "ALTER TABLE #{partition_table_name} ADD PRIMARY KEY (id);"
        execute_sql(sql)

        create_partition_indexes(partition_table_name)
        create_partition_named_indexes(partition_table_name)
        create_partition_unique_indexes(partition_table_name)
        create_partition_named_unique_indexes(partition_table_name)
      end

      def drop_month_table(date=Date.today)
        sql = "DROP TABLE IF EXISTS #{name_of_partition_table(date)};"
        execute_sql(sql)
      end

      def create_partitioning_by_month_trigger_sql
        "CREATE OR REPLACE FUNCTION #{table_name}_insert_trigger() RETURNS trigger AS
    $$
           DECLARE
             curY varchar(4);
             curM varchar(2);
             tbl varchar(30);
           BEGIN
              select cast(DATE_PART('year', new.#{parting_column}) as varchar) into curY;
              select lpad(cast(DATE_PART('month', new.#{parting_column}) as varchar), 2, '0') into curM;
              tbl := '#{table_name}_y' || curY || 'm' || curM;
              EXECUTE format('INSERT into %I values ($1.*);', tbl) USING NEW;
              return NEW;
           END;
           $$
         LANGUAGE plpgsql;

         CREATE TRIGGER #{table_name}_insert
         BEFORE INSERT ON #{table_name}
         FOR EACH ROW
         EXECUTE PROCEDURE #{table_name}_insert_trigger();

         -- Trigger function to delete from the master table after the insert
         CREATE OR REPLACE FUNCTION #{table_name}_delete_trigger() RETURNS trigger
             AS $$
         DECLARE
             r #{table_name}%rowtype;
         BEGIN
             DELETE FROM ONLY #{table_name} where id = new.id returning * into r;
             RETURN r;
         end;
         $$
         LANGUAGE plpgsql;

         CREATE TRIGGER #{table_name}_after_insert
         AFTER INSERT ON #{table_name}
         FOR EACH ROW
         EXECUTE PROCEDURE #{table_name}_delete_trigger();"
      end

      def drop_partitioning_by_month_trigger_sql
        "DROP TRIGGER #{table_name}_insert ON #{table_name};
         DROP FUNCTION #{table_name}_insert_trigger();
         DROP TRIGGER #{table_name}_after_insert ON #{table_name};
         DROP FUNCTION #{table_name}_delete_trigger();"
      end

      def create_partition_indexes(partition_table_name)
        custom_indexes = partition_table_indexes.presence
        return unless custom_indexes

        custom_indexes.each { |custom_index| create_custom_index(partition_table_name, custom_index) }
      end

      def create_partition_named_indexes(partition_table_name)
        custom_indexes = partition_table_named_indexes.presence
        return unless custom_indexes

        custom_indexes.map{|name, custom_index|
          index_name = "index_#{partition_table_name}_#{name}"
          create_custom_named_index(partition_table_name, custom_index, index_name)
        }
      end

      def create_partition_unique_indexes(partition_table_name)
        custom_unique_indexes = partition_table_unique_indexes.presence
        return unless custom_unique_indexes

        custom_unique_indexes.each { |custom_index| create_custom_index(partition_table_name, custom_index, true) }
      end

      def create_partition_named_unique_indexes(partition_table_name)
        custom_indexes = partition_table_named_unique_indexes.presence
        return unless custom_indexes

        custom_indexes.map{|name, custom_index|
          index_name = "index_#{partition_table_name}_#{name}"
          create_custom_named_index(partition_table_name, custom_index, index_name, true)
        }
      end

      def create_custom_index(table_name, index_fields, is_unique = false)
        ActiveRecord::Migration.add_index table_name, index_fields, unique: is_unique
      end

      def create_custom_named_index(table_name, index_fields, name, is_unique = false)
        ActiveRecord::Migration.add_index table_name, index_fields, name: name, unique: is_unique
      end

      def name_of_partition_table(date=Date.today)
        date.strftime("#{table_name}_y%Ym%m")
      end

      # Template method
      # Column which will determine partition for row (must be date or datetime type). Default value is :created_at
      def parting_column
        :created_at
      end

      # Template method
      def partition_table_indexes
        #
      end

      def partition_table_named_indexes
        #
      end

      # Template method
      def partition_table_unique_indexes
        #
      end

      # Template method
      def partition_table_named_unique_indexes
        #
      end
    end
  end
end
