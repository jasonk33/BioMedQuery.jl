using MySQL

"""
    init_mysql_database(;host = "127.0.0.1", dbname="test",
    username="root", pswd="", mysql_code=nothing, overwrite=false)

Create a MySQL database using the code inside mysql_code

### Arguments

* `host`, `dbname`, `user`, `pswd`
* `mysql_code::String`: String with MySQL code that crates all default tables
* `overwrite::Bool` : Flag, if true and dbname exists, drops all database and re-creates it

### Output

* `con`: Database connection and table-column names map

"""
function init_mysql_database(;host = "127.0.0.1", dbname="test",
    username="root", pswd="", mysql_code=nothing, overwrite=false)

    # call shell to ensure the MySQL server is running
    # run(`mysql.server start`)

    # Connecting to MySQL, but not to a specific DB,
    # we then create DB we want
    con = mysql_connect(host, username, pswd)

    q = mysql_execute(con, "SHOW DATABASES LIKE '$dbname'; ")
    if length(q[1])>0
        if overwrite
            println("Set to overwrite MySQL database $dbname")
            mysql_execute(con, "DROP DATABASE IF EXISTS $dbname;")
            mysql_execute(con, "CREATE DATABASE $dbname
                CHARACTER SET utf8 COLLATE utf8_unicode_ci;")
        end
    else
        mysql_execute(con, "CREATE DATABASE $dbname
            CHARACTER SET utf8 COLLATE utf8_unicode_ci;")
    end


    con = mysql_connect(host, username, pswd, dbname)

    if mysql_code != nothing
        mysql_execute(con, mysql_code)
        println("Database $dbname created and initialized")
    else
        println("Empty Database Created")
    end

    return con
end


"""
    select_columns_mysql(con, table)

For a MySQL database, return an array of all columns in the given table
"""
function select_columns(con::MySQL.MySQLHandle, table)
    cols_query = mysql_execute(con, "SHOW COLUMNS FROM $table;")
    cols_query[1]
end

"""
    select_all_tables_mysql(con)

Return an array of all tables in a given MySQL database
"""
function select_all_tables(con::MySQL.MySQLHandle)
    tables_query = mysql_execute(con, "SHOW TABLES;")
    tables_query[1]
end

function print_error(con::MySQL.MySQLHandle)
    Base.showerror(STDOUT, MySQLInternalError(con))
    println("\n")
end

"""
    query_mysql(con, query_code)

Execute a mysql command
"""
function db_query(con::MySQL.MySQLHandle, query_code)
    try
        sel = mysql_execute(con, query_code)
        return sel
    catch
        throw(MySQLInternalError(con))
    end
end

function insert_row!{T}(con::MySQL.MySQLHandle, tablename, data_values::Dict{Symbol, T},
    colname_dict::Dict{String, Array{String, 1}}, verbose = false)

    table_cols = colname_dict[symbol(tablename)]
    table_cols_backticks = [string("`", x, "`") for x in table_cols]
    cols_string = join(table_cols_backticks, ", ")
    vals_string = assemble_vals(data_values, table_cols)
    lastid = -1

    try
        lastid = mysql_execute(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;
         SELECT LAST_INSERT_ID();")[2][1,1]
    catch e
        # Base.showerror(STDOUT, MySQLInternalError(con))
        println("\n")
        println("Warning: Row with values $vals_string not inserted into the table: $tablename")
        # throw(MySQLInternalError(con))
    end
    return lastid
end


"""
    insert_row!(db, tablename, values)
Insert a row of values into the specified table for a given a MySQL database handle

### Arguments:

* `db::MySQLDB`: Database object (connection and map)
* `data_values::Dict{String, Any}`: Array of (string) values
* `verbose`: Print debugginh info
"""
function insert_row!{T}(con::MySQL.MySQLHandle, tablename, data_values::Dict{Symbol, T},
    verbose = false)

    cols_string, vals_string = assemble_cols_and_vals(data_values)
    lastid = -1
    try
        q = db_query(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;
        SELECT LAST_INSERT_ID();")
        lastid = q[2][1,1]
    catch
        if verbose
            println("Warning! Row with values $vals_string not inserted into the table: $tablename")
            Base.showerror(STDOUT, MySQLInternalError(con))
            println("\n")
        end
        # throw(MySQLInternalError(con))
    end
    return lastid
end

function create_server(con::MySQL.MySQLHandle, dbname; linkname = "fedlink", user="root", psswd="", host="127.0.0.1", port=3306)

    query_str = "CREATE SERVER $linkname
                 FOREIGN DATA WRAPPER mysql
                 OPTIONS (USER '$user', PASSWORD '$psswd', HOST '$host', PORT $port, DATABASE '$dbname');"

    mysql_execute(con, query_str)
end
