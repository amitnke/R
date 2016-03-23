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
val input3 = sc.parallelize(Array(("1",2), ("3",4), ("3",6)), (" ",10))

Simple filter operation on pair RDDs:-
input3.filter{case (key, value) => value == 10)
input3.filter{case (key, value) => key != "")

###Sometimes working with pairs can be awkward if we want to access only the values part of our pair RDD. Since this is common patternm Spark provide the mapValues(func) function, which is the same as :-
map{case (x,y): (x: func(y))}