* RDD containing key/value are called pair RDDs.
* Pair RDDs have a reduceByKey() method that can aggregate data separately for each key, and a join() method that cab merge two RDDS together by grouping elements with the same key. 
* It is common to extract firelds from an RDD and use those fields as key in pair RDD operations. 

########Creating Pair RDDs########
a. Many format directly return pair RDDs for their key/value data. 
b. Regular RDD  can be converted in to pair RDD using map() method. 

** In SCALA, for the function on keyed data to be available, we also need to return tuple. An implicit conversion on RDDs of tuples exists to provide the additional key/value functions. 
## Creating a pair RDD using the first word as the key in Scala
val pairs = lines.map(x => (x.split(" ")(0),x))

* When creating a pair RDD from an in-memory collection in Scala and Python, we only need to call SparkContext.parallelize() on a collection of pairs. 
##########Transformation on pair RDDs###############
*pair RDDsa are allowed to use all transformations availabe to standard RDDs. Since pair RDDs contains tuple, we need to pass functions that operate on tuples rather than individual elements. 

val input = sc.parallelize(Array(("1",2), ("3",4), ("3",6)))
input.reduceByKey((x,y) => x+y) ##res16: Array[(String, Int)] = Array((1,2), (3,10))
input.groupByKey()  ##res17: Array[(String, Iterable[Int])] = Array((1,CompactBuffer(2)), (3,CompactBuffer(4, 6)))
input.mapValues(x => x+1) ##res19: Array[(String, Int)] = Array((1,3), (3,5), (3,7))
input.flatMapValues(x => (x to 5)) 	## res20: Array[(String, Int)] = Array((1,2), (1,3), (1,4), (1,5), (3,4), (3,5))
input.key 	###res28: Array[String] = Array(1, 3, 3)
input.values  ## res30: Array[Int] = Array(2, 4, 6)
input.sortBuKey()  ##res33: Array[(String, Int)] = Array((1,2), (3,4), (3,6))

########Transformation on two pair RDDS#####################
val input2 = sc.parallelize(Array(("3",9)))
input.subtractByKey(input2)   ###res34: Array[(String, Int)] = Array((1,2))
input.join(input2)   	###res35: Array[(String, (Int, Int))] = Array((3,(4,9)), (3,(6,9)))
input.rightOuterJoin(input2).collect()    ### res36: Array[(String, (Option[Int], Int))] = Array((3,(Some(4),9)), (3,(Some(6),9)))
input.leftOuterJoin(input2).collect()		###res37: Array[(String, (Int, Option[Int]))] = Array((1,(2,None)), (3,(4,Some(9))), (3,(6,Some(9))))
input.cogroup(input2).collect()				####res38: Array[(String, (Iterable[Int], Iterable[Int]))] = Array((1,(CompactBuffer(2),CompactBuffer())), (3,(CompactBuffer(4, 6),CompactBuffer(9))))

*********************get an understanding of Option, Some and CompactBuffer********************************
<a name="val input3 = sc.parallelize(Array(("1",2), ("3",4), ("3",6)), (" ",10))
"></a>
Simple filter operation on pair RDDs:-
input3.filter{case (key, value) => value == 10)
input3.filter{case (key, value) => key != "")

###Sometimes working with pairs can be awkward if we want to access only the values part of our pair RDD. Since this is common patternm Spark provide the mapValues(func) function, which is the same as :-
map{case (x,y): (x: func(y))}

## When datasets are described in terms of key/value pairs, it is common to want to aggregate statistics across all elements with the same key. 
# Spark has set of operation that combines the values that have the same key. 
# These operation return RDDs and thus are transformations rather than actions. 
** reduceByKey() is quite similar to reduce(); both takes a function and use it to combine values. reduceByKey() runs several parallel reduce operations, one for each key in the dataset, where each operation combines values that have the same key. It is not implemented as an action that returns values to the user program. Instead, it returns a new RDD consisting of each key and the reduced value for that key. 
** foldByKey() is quite similar to fold(); both uses a zero value of the same type if the data in our RDD and combination function. As with fold(), the provided zero value for foldByKey() should have no impact when added with your combination function to another element. 
val input = sc.parallelize(Array(("panda", 0), ("pink", 3), ("pirate",3), ("panda",1), ("pink",4)))
input.mapValues(x => (x,1)).reduceByKey((x,y) => (x._1 + y._1, x._2 + y._2)).collect()
#res3: Array[(String, (Int, Int))] = Array((pirate,(3,1)), (panda,(1,2)), (pink,(7,2)))

##Words Count in Scala
val input = sc.textFile("/Users/amit/R/README.rmd")
val words = input.flatMap(x => x.split(" "))
val result = words.map(x => (x,1)).reduceByKey((x,y) => x+y)
##input.flatMap(x => x.split(" ")).countByValue() ## no need to collect. It will throw op to program.

##combineByKey() is the most general of the per-key aggregation function. Like aggregate(), combineByKey() allows the user to return values that are not the same
type as our input data. 
** As combineByKey() goes through the elements in a partition, each element either has a key it hasn't seen before or has the same key as a previous element. 
** If it's a new element, combineByKey() uses a function we provide, called createCombine(), to create the initial value for the accumulator or that key. If it is a value we have seen before while processing, it will instead use the provided function, mergeValue(), with the current value of accumulator for that key and the new value. 
** Since each partition is processed independently, we can have multiple accumulators for the same key. mergeCombiners() function get called to merge accumulator for the same key.

val result = input3.combineByKey((v) => (v,1),
     | (acc: (Int,Int), v) => (acc._1 + v, acc._2 + 1),
     | (acc1: (Int, Int), acc2: (Int, Int)) => (acc1._1 +acc2._1, acc1._2 + acc2._2)
     | ).map{case (key,value) => (key,value._1/value._2.toFloat)}
result: org.apache.spark.rdd.RDD[(String, Float)] = MapPartitionsRDD[2] at map at <console>:26
result.collectAsMap().foreach(println(_))
( ,10.0)
(1,2.0)
(3,5.0)

##Every RDD has a fixed number of partitions that determine the degree of parallelism to use when executing operation on RDD. 
Most of the operators accept a second parameter giving the number of partitions to use when creating the grouped or aggregated RDD, 
scala > val data = Seq(("a",3), ("b",4), ("c",5),("a",2))
data: Seq[(String, Int)] = List((a,3), (b,4), (c,5), (a,2))
scala > sc.parallelize(data).reduceByKey((x,y) => x+y)
res2: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at reduceByKey at <console>:24
scala > sc.parallelize(data).reduceByKey((x,y) => x+y, 10)
res1: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[3] at reduceByKey at <console>:24

