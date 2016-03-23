###SCALA Notes(Programming with RDDs:-
##Basic command
val lines = read.textFile("PATH"), val lines = sc.parallelize("I","am a boy","and","you","are a girl")
lines.count(), lines.take(n),  lines.first(), lines.persist
lines.filter(line => line.contains("error")).union(lines.filter(line => line.contains("warning")))
println("The count in the line variable is: " + lines.count()+ "."). 
lines.take(10).foreach(println)
##Passing function to SPARK
class SearchFunctions(val query: String){
	def isMatch(s: String): Boolean = {
		s.contains(query)
	}
	def getMatchFunctionReference(rdd: RDD[String]): RDD[Boolean] = {
		//Problem: "isMatch" means "this.query", so we pass all of "this"
		rdd.map(isMatch)
	}
	def getMatchesFieldReference(rdd: RDD[String]): RDD[ARRAY[STRING]] = {
		//Problem: "query" means "this.query", so we pass all of "this"
		rdd.map(x => x.split(query))
	}
	def getMatchesNoReference(rdd: RDD[String]): RDD[Array[String]] = {
		//Safe: extract just the fiels we need into a local variable
		val query = this.query
		rdd.map(x => x.split(quert_))
	}
}
## Element-wise transformation(map and filter)
# map(): It takes in a function and applies it to each element in the RDD with the result of the function being the new value of each element in the resulting RDD. 
# filter(): It takes in a function and returns an RDD that only has elements that pass the filter() function. 

# Scala squaring the vales in an RDD
val input = sc.parallelize(List(1,2,3,4))
val result = input.map(x => x*x)
prinln(result.collect().mkString(","))
##Sometimes we want to produce multiple output element for each input element. The operation to this is called flatMap(). Instead of returning a sinle element, we retutn an iterator with our return values. 
## rather than producing an RDD of iterator, we get back an RDD that consists of the elements from all of the iterators. 
val cifc15 = sc.textFile("hdfs locaiton of file")
cifc15.take(1).flatMap(line => line.split(",")).headOption ## This will return first element of the 1st record from hdfs file

##Set operation in SCALA
RDD1.distinct() ## RDD is expensive, as it requires shuffling all the data over the network to ensure that we receive only one copy of each element. 
RDD1.union(RDD2) ## it will contain duplicates if input rdd has duplicate. 
RDD1.intersection(RDD2) ## It will return only element in both RDDs. It also removes duplicate. Performance will be even worse as it requires shuffle over the network to identify common element. 
RDD1.subtract(RDD2) ## It will return element in RDD1 that are not present in RDD2. It performs a shuffle. 
RDD1.cartesian(RDD2) ## It will return all possible pair of (a,b) where a is in the source RDD and b is in the other RDD. It is very expensive for large RDD. 

###Action - 
##reduce - which takes a function that operate on two elements of the tupe in your RDD and return a new element of the same type. 
##sum, count and other aggregation using reduce
val sum = rdd.reduce((x,y) => x+y)

##Similar to reduce() is fold(), which also takes a function with the same signature as needed for reduce() but in addition takes a ""zero value" to be used for the initial call on each partition. 

#Both fold() and reduce() require that the return type of our result be the same type as that of the elements in the RDD we are operating over. but in case of finding average, we need to keep track of count and number of elements as well, which require us to return a pair. 
# map()can do this by transforming each element into element and the number 1. 
##The aggregate() function frees us from the constraint of having the return be the same type as the RDD. 
##With aggregate(), like fold(), we supply an initial zero value of the type we want to return. We then supply a function to combine the elements from our RDD with the accumulator. 
#Finally, we need to supply a second function to merge two accumulators, guven that each node accumulates its own result locally. 

######Aggregate() in SCALA#######
val result = input.aggregate((0, 0))(	## Initialize an aggregator
               (acc, value) => (acc._1 + value, acc._2 + 1), 	## first function is to evaluate sum and count on a accumulator
               (acc1, acc2) => (acc1._1 + acc2._1, acc1._2 + acc2._2))		## This is to clun the result acrss accumulators. 
val avg = result._1 / result._2.toDouble

### Some actions return entire RDD's content to driver program. Ex. collect(). Also entire content are expected to fit in memory as it all needs to be copied to the driver.
## take(n) return n element from the RDD and attempts to minimize the number of partition it access. 
## top(n) - will give sample of records from top. 
## takeSample(withreplacement, num, seed) - take a sample of our data either with or without replacement. 


###$$$ to perform an action on all elements in The RDD, but without returning any result to the driver program. Ex - JSON to webserver, inserting records in database. In either case foreach() action perform computation on each element in th eRDD without bringing it back locally. 
##input = sc.parallelize(List(1,2,3,4,5,6,7,4))

###input.count() =====>   count of the element. 
res3: Long = 8
###input.countByValue() ==>
scala.collection.Map[Int,Long] = Map(5 -> 1, 1 -> 1, 6 -> 1, 2 -> 1, 7 -> 1, 3 -> 1, 4 -> 2)

####Functions of numeric RDDs - 
mean(), variance()

###Key/value pair RDD
join()

####### Persistence(Caching) #######
Spark will recompute the RDD and all of its dependencies each time we call an action on the RDD. This can be especially expensive for iterative algorithms, which look at the data many times. 
val result = input.map(x => x*x)
println(result.count())
println(result.collect().mkString(","))

To avoid computing RDD multiple times, we can ask Spark to persist the data. It will make node to store their partition and if a node fails, Spark will recompute the lost partitions of the data when needed. 
We can also replicate our data on multiple nodes of we want to be able to handle node failure without slowdown. 
##Default persist() will store the data in the JVM heap as unserialized objects. When we write data out to disk or off-heap storage, that data is always serialized. 

import org.apache.spark.storage.StorageLevel
val result = input.map(x => x * x)
result.persist(StorageLevel.DISK_ONLY)
println(result.count())
println(result.collect().mkString(","))

### we can use MEMORY_ONLY, MEMORY_ONLY_SER, MEMORY_AND_DISK, MEMORY_AND_DISK_SER and DISK_ONLY instead of StorageLevel.DISK_ONLY. Each only have different Space used, CPU time. 

## we call persist() on the RDD before the first action. 
## If you attemt to cache too much data to fit in memory, Spark will automatically evict old partitions using a least recently used. 
