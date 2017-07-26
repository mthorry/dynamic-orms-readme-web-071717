require_relative "../config/environment.rb"
require 'active_support/inflector' #allows you to do stuff like 'pluralize'

class Song


  def self.table_name # Song.table_name
    self.to_s.downcase.pluralize
  # Song>"Song">"song" >"songs"
  end



  def self.column_names
    DB[:conn].results_as_hash = true # sets results as hash instead of nested array

    sql = "pragma table_info('#{table_name}')" #this can be run to get info in table

    table_info = DB[:conn].execute(sql) # now table info is set to a HASH of the database
    column_names = [] #create empty array for column names
    table_info.each do |row| #iterate through the table info HASH. Each row represents a row of info in table
      column_names << row["name"] #pulls the value connected to the name key and adds it to column_names
    end
    column_names.compact # add .compact to remove any nils
  end # => ["id", "name", "album"]



  self.column_names.each do |col_name| #iterates through column_names array
    attr_accessor col_name.to_sym # creates attr_accessor for each item in the column_names array and converts from string to symbol (.to_sym)
  end



  def initialize(options={}) # defaults to empty hash
    options.each do |property, value|
      self.send("#{property}=", value) #sets each property equal to a KEY and value as its value, as long as each property has an associated attr_accessor
    end
  end



  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    # this uses the table_name_for_insert helper method to gather the name of the table
    # then it uses the values_for_insert helper method to gather the values
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    # sets the instance id equal to the id assigned from the table (unique ID)
  end



  def table_name_for_insert
    self.class.table_name # self here is instance so we need .class to get the class.table_name method. would be song.Song.table_name => "songs"
  end



  def values_for_insert # save helper method
    values = [] # create empty array to hold values
    self.class.column_names.each do |col_name| # iterates trhough the column_names by using the column_names helper method. For each column name
      values << "'#{send(col_name)}'" unless send(col_name).nil? # adds the column name unless that value is nil
    end
    values.join(", ") # joins values into array using commas
  end



  def col_names_for_insert # save helper method
    self.class.column_names.delete_if {|col| col == "id"}.join(", ") # deletes any id columns bc we don't want to insert an ID -- that's the table.create job!
  end



  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



