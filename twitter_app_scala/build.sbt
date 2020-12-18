name := "tp_pipeline"

version := "0.1"

scalaVersion := "2.11.12"
libraryDependencies += "com.amazonaws" % "aws-java-sdk-kinesis" % "1.11.880"
libraryDependencies += "com.amazonaws" % "aws-java-sdk-core" % "1.11.880"
libraryDependencies += "org.apache.bahir" %% "spark-streaming-twitter" % "2.3.2"
// https://mvnrepository.com/artifact/org.apache.spark/spark-hive
//libraryDependencies += "org.apache.bahir" %% "spark-streaming-twitter" % "1.6.2"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "1.6.2",
  "org.apache.spark" %% "spark-streaming" % "2.4.0",
  "org.apache.spark" %% "spark-sql" % "1.6.2",
  "org.apache.spark" %% "spark-mllib" % "1.6.2"
)
