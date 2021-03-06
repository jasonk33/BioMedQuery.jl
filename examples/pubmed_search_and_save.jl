# Example Julia script calling the typical workflow to  search PubMed and store
# the results in a database
# Date: September 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.Processes
using BioMedQuery.Entrez

#************************ LOCALS TO CONFIGURE!!!! **************************
email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 20
overwrite=true
verbose = false

results_dir = "./results"


#Database backend
using_sqlite=false
using_mysql=false
using_endnote=true
using_xml=false

#***************************************************************************
if !isdir(results_dir)
    mkdir(results_dir)
end


if using_mysql
    #************************ LOCALS TO CONFIGURE!!!! **************************
    host="localhost" #If want to hide - use enviroment variables instead
    mysql_usr="root"
    mysql_pswd=""
    dbname="pubmed_obesity_2010_2012"
    #***************************************************************************
    config = Dict(:host=>host,
                     :dbname=>dbname,
                     :username=>mysql_usr,
                     :pswd=>mysql_pswd,
                     :overwrite=>overwrite)
    save_func = save_efetch_mysql
elseif using_sqlite
    #************************ LOCALS TO CONFIGURE!!!! **************************
    db_path="results_dir/pubmed_obesity_2010_2012.db"
    #***************************************************************************

    config = Dict(:db_path=>db_path,
                        :overwrite=>overwrite)
    save_func = save_efetch_sqlite
elseif using_endnote
    #************************ LOCALS TO CONFIGURE!!!! **************************
    citation_type="endnote"
    output_file="results_dir/pubmed_obesity_2010_2012.enw"
    #***************************************************************************
    config = Dict(:type => citation_type, :output_file => output_file, :overwrite=> overwrite)
    save_func = save_article_citations
elseif using_xml
    #************************ LOCALS TO CONFIGURE!!!! **************************
    output_file="results_dir/pubmed_obesity_2010_2012.xml"
    #***************************************************************************
    config = Dict(:output_file => output_file, :overwrite=> overwrite)
    save_func = save_efetch_xml
else
   error("Unsupported database backend, options are: sqlite, mysql, endnote")
end


@time begin
    db = pubmed_search_and_save(email, search_term, max_articles,
    save_func, config, verbose)
end
