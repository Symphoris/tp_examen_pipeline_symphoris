import java.nio.ByteBuffer

import com.amazonaws.auth.{AWSStaticCredentialsProvider, DefaultAWSCredentialsProviderChain}
import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder
import com.amazonaws.services.kinesis.model.{PutRecordsRequest, PutRecordsRequestEntry, PutRecordsResult}
import org.apache.spark.SparkConf
import org.apache.spark.sql.DataFrame
import org.apache.spark.streaming.{Seconds, StreamingContext}
import org.apache.spark.streaming.twitter.TwitterUtils
import twitter4j.auth.OAuthAuthorization
import twitter4j.conf.ConfigurationBuilder

object TwitterTPPipeline {

  def main(args: Array[String]) {
    import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder
    import com.amazonaws.services.kinesis.model.PutRecordsRequest
    import com.amazonaws.services.kinesis.model.PutRecordsRequestEntry
    import com.amazonaws.services.kinesis.model.PutRecordsResult
    import java.nio.ByteBuffer
    import java.util
    val twitterCredentials = new Array[String](4);
    //consumerKey
    twitterCredentials(0) = "XXXXXXXXXXXXXXXXXXXXXXXXXX";
    //consumerSecret
    twitterCredentials(1) = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

    //accessToken
    twitterCredentials(2) =  "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    //accessTokenSecret
    twitterCredentials(3) = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

    val appName = "TweeterStreamReader"
    val conf = new SparkConf().setAppName(appName).setMaster("local[2]")
    val ssc = new StreamingContext(conf, Seconds(5))
    val Array(consumerKey, consumerSecret, accessToken, accessTokenSecret) = twitterCredentials.take(4)

    val filters = args.takeRight(args.length - 4)

    val cb = new ConfigurationBuilder
    cb.setDebugEnabled(true).setOAuthConsumerKey(consumerKey)
      .setOAuthConsumerSecret(consumerSecret)
      .setOAuthAccessToken(accessToken)
      .setOAuthAccessTokenSecret(accessTokenSecret)

    val auth = new OAuthAuthorization(cb.build)
    val tweets = TwitterUtils.createStream(ssc, Some(auth), filters)
    val englishTweets = tweets.filter(_.getLang() == "en")
    englishTweets.print()
    englishTweets.repartition(1)
    val hashTags = englishTweets.flatMap(status => status.getText.split(" ").filter(_.startsWith("@")))
   // afficher les tweets tous les 45 secondes
    val topCounts45 = hashTags.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(45))
      .map { case (topic, count) => (count, topic) }
      .transform(_.sortByKey(false))
    val credentials = new DefaultAWSCredentialsProviderChain
    val kinesisClient = AmazonKinesisClientBuilder.standard()
      .withCredentials(new AWSStaticCredentialsProvider(credentials.getCredentials))
      .withRegion("eu-west-1").build()
    val putRecordsRequest = new PutRecordsRequest
    putRecordsRequest.setStreamName("sympho2")
    val putRecordsRequestEntryList = new util.ArrayList[PutRecordsRequestEntry]
    topCounts45.foreachRDD(rdd => {
      val topList = rdd.take(20)

      topList.foreach { case (count, tag) => println("%s (%s tweets)".format(tag, count))
        val myString: String = "%s (%s tweets)".format(tag, count) + "\n"
        val putRecordsRequestEntry = new PutRecordsRequestEntry
        putRecordsRequestEntry.setData(ByteBuffer.wrap(myString.getBytes))
        putRecordsRequestEntry.setPartitionKey(String.format("sympho2"))
        putRecordsRequestEntryList.add(putRecordsRequestEntry)
        putRecordsRequest.setRecords(putRecordsRequestEntryList)
        val putRecordsResult: PutRecordsResult = kinesisClient.putRecords(putRecordsRequest)
        System.out.println("Put Result" + putRecordsResult)
      }
    })

    ssc.start()
    ssc.awaitTermination()
  }
}
