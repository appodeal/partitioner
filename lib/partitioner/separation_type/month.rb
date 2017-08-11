module SeparationType::Month
  def create_next_month_table
    create_month_table(Date.today.next_month)
  end

  def drop_old_month_table
    drop_month_table(Date.today.prev_month.prev_month)
  end

  def create_month_table(date=Date.today)
    date_start = date.at_beginning_of_month
    date_end = date.at_beginning_of_month.next_month
    sql = "CREATE TABLE IF NOT EXISTS #{name_of_partition_table(date)} (
           CHECK ( created_at >= DATE('#{date_start}') AND created_at < DATE('#{date_end}') )
           ) INHERITS (#{table_name});"
    execute_sql(sql)
    sql = "ALTER TABLE #{name_of_partition_table(date)} ADD PRIMARY KEY (id);"
    execute_sql(sql)
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
          select cast(DATE_PART('year', new.created_at) as varchar) into curY;
          select lpad(cast(DATE_PART('month', new.created_at) as varchar), 2, '0') into curM;
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

  def name_of_partition_table(date=Date.today)
    date.strftime("#{table_name}_y%Ym%m")
  end
end
