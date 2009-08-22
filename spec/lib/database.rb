ActiveRecord::Migration.verbose = false unless ENV.has_key?('DEBUG')

module ScopedSearch::Spec::Database

  def self.establish_connection
    if ENV['DATABASE']
      self.establish_named_connection(ENV['DATABASE'])
    else
      self.establish_default_connection
    end  
  end

  def self.establish_named_connection(name)
    @database_connections ||= YAML.load(File.read("#{File.dirname(__FILE__)}/../database.yml"))
    raise "#{name} database not configured" if @database_connections[name.to_s].nil?
    ActiveRecord::Base.establish_connection(@database_connections[name.to_s])
  end

  def self.establish_default_connection
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
  end

  def self.close_connection
    ActiveRecord::Base.remove_connection
  end
  
  def self.create_model(fields)
    table_name = "model_#{rand}".gsub(/\./, '')
    ActiveRecord::Migration.create_table(table_name) do |t| 
      fields.each do |name, field_type| 
        t.send(field_type.to_s.gsub(/^unindexed_/, '').to_sym, name)
      end
    end
    
    klass = Class.new(ActiveRecord::Base)
    klass.set_table_name(table_name)

    fields.reject { |n, t| /^unindexed_/ =~ t.to_s}.keys.each do |field|
      klass.scoped_search.on(field)
    end
    
    return klass
  end
  
  def self.drop_model(klass)
    ActiveRecord::Migration.drop_table(klass.table_name)
  end
end