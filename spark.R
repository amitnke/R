spark_path <- strsplit(system("brew info apache-spark",intern=T)[4],' ')[[1]][1] # Get your spark path
.libPaths(c(file.path(spark_path,"libexec", "R", "lib"), .libPaths())) # Navigate to SparkR folder
library(SparkR)
sc <- sparkR.init()
sqlContext <- sparkRSQL.init(sc)
df <- createDataFrame(sqlContext, faithful)
sparkR.stop()
sc <- sparkR.init(sparkPackages="com.databricks:spark-csv_2.11:1.0.3")
sqlContext <- sparkRSQL.init(sc)
##people <- read.df(sqlContext, "./examples/src/main/resources/people.json", "json")
df <- createDataFrame(sqlContext, faithful)
printSchema(df)
write.df(df, path="people.parquet", source="parquet", mode="overwrite")
# sc is an existing SparkContext.
hiveContext <- sparkRHive.init(sc)
sql(hiveContext, "CREATE TABLE IF NOT EXISTS src (key INT, value STRING)")
sql(hiveContext, "LOAD DATA LOCAL INPATH 'examples/src/main/resources/kv1.txt' INTO TABLE src")