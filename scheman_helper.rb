require "yaml"
module SchemanHelper
  
  DS  = "public"
  YBD = "config/database.yml"
  DMG = "db/migrate"
  
  @@pgcdef = {
     :adapter => "postgresql",
     :port=>5432,
     :username=>"postgres", 
     :password=>"postgres",
     :min_messages=>"log", 
     :template=>"template0",
     :host=>"localhost", 
     :schema_search_path=>"public", 
     :encoding=>"utf8" 
  }
  
  
  
  ####################################################
  
  ## Database  schemas
  ####################################################

  def self.demo(schema="runtime_schema")
    create_schema(schema)
    migrate_schema(schema)
    publik
  end
  
  def self.switch_schema(schema)
    config = load[RAILS_ENV]
    switch(config, schema)
  end
  
  def self.migrate_schema(schema)
    config = load[RAILS_ENV]
    switch(config, schema)
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"].presence)
  end
  
  def self.publik
    config = load[RAILS_ENV]
    switch(config)
  end
  
  def self.create_schema(schema)
    conn.execute("CREATE SCHEMA #{schema}")
    append_schema_back("#{schema}")
  end
  
  # doesn't synchronize with ActiveResord
  def self.set_schema(schema)
    conn.execute("SET search_path TO #{schema}")
  end    
  def self.append_schema_front(schema)
    conn.execute("SET search_path TO #{schema}, #{conn.schema_search_path}")
  end
  def self.append_schema_back(schema)
    conn.execute("SET search_path TO #{conn.schema_search_path}, #{schema}")
  end
  
  
  
  
  ####################################################
  
  ## Database  connections
  ####################################################
  
  def self.conn
    ActiveRecord::Base.connection
  end
  
  def self.make(config)
    ActiveRecord::Base.establish_connection(config)
  end
  
  def self.switch(config, schema = nil)
    schema ||= DS
    config["schema_search_path"] = schema 
    conn.execute("SET search_path TO #{schema}")
    make(config)
  end
  
  
  
  
  ####################################################
  
  ## Database  configurations 
  ####################################################
  
  def self.find_config(name)
    all_configs[name]
  end
  
  def self.all_configs
    ActiveRecord::Base.configurations
  end
  
  def self.load(path = nil)
    path ||= DS
    YAML::load(File.open(YBD))
  end
  
  def self.dump(configs, path = nil)
    path ||= DS
    File.new(path || "w").write(YAML::dump(configs)).close
  end
  
  def self.persist(configs, path)
    if(!configs || !configs.is_a?(Hash))
      raise ArgumentError(
        %( Provide single config! If schema name is not provided, 
           schema will be switched to default, which is 'public'. ) ) 
    end
    dump(configs, path.presence)
  end

  # Makes new PG connection           
  # create_db({
  #   :database => "lab_development_2",
  #   :adapter => "postgresql",
  #   :username => "postgres"
  # })  
  def self.create_db(config)
    raise ArgumentError, "Missing argument: database." if !config.has_key?(:database)
    conn.create_database(config[:database])
    make(config)
    conn.reconnect! if conn.requires_reloading?
    clear_active_cache
  end
  
  def self.clear_active_cache
    
  end


  
  
  
  ####################################################
  
  ## ActiveRecord 
  ####################################################

  # SchemanHelper.ars.each{ ... 
  # <~ for application module, load 'app/models' 
  # 
  # SchemanHelper.ars("Labis::DataModel").each{ ...
  # <~ for specific modules
  #
  def self.ars(model_namespace=nil)
    if model_namespace.nil?
      base
    else
      base.collect{|a| a.name if a.name.starts_with? model_namespace}
    end
  end
  
  def self.base
    subclasses_of(ActiveRecord::Base)    
  end
  

  
  
  ####################################################
  
  ## Migrations 
  ####################################################
  
  def self.current_migration
    ActiveRecord::Migrator.current_version
  end
  
  def self.all_migrations
    ActiveRecord::Migrator.get_all_versions
  end

  
end
