import org.apache.spark.sql.functions._

try {
    require(sc.master == "yarn", "Spark must run under YARN")
    require(sc.applicationId.startsWith("application_"), "No YARN application ID")

    println("YARN application: " + sc.applicationId)
    println("Spark master: " + sc.master)

    val input = sc.getConf.get("spark.hw4.input")
    val output = sc.getConf.get("spark.hw4.output")
    require(input.startsWith("hdfs://"), "Input must be on HDFS")
    require(output.startsWith("hdfs://"), "Output must be on HDFS")


    val raw = spark.read
        .option("delimiter", "\t")
        .option("header", "false")
        .option("mode", "FAILFAST")
        .option("basePath", input)
        .csv(input)

    raw.show(false)

    val typed = raw.select(
        lower(trim(col("_c0"))).as("colour"),
        col("_c1").cast("int").as("number"),
        col("dt").cast("string").as("dt")
    )

    require(typed.count() > 0, "Input is empty")
    require(
        typed.filter(col("colour").isNull || col("number").isNull || col("dt").isNull).count() == 0,
        "Invalid input values"
    )

    val summary = typed.groupBy("dt", "colour").agg(
        count(lit(1)).as("row_count"),
        sum(col("number").cast("long")).as("total_number"),
        max(col("number")).as("max_number")
    )

    summary.orderBy("dt", "colour").show(false)
    summary.printSchema()

    summary.write
        .mode("overwrite")
        .partitionBy("dt")
        .parquet(output)

    val saved = spark.read.parquet(output)
    require(saved.count() == summary.count(), "Saved row count differs")
    println("OK: Spark transformed HDFS data and saved partitioned Parquet")

    spark.stop()
    System.exit(0)
} catch {
    case error: Throwable =>
        error.printStackTrace()
        try { spark.stop() } catch { case _: Throwable => () }
        System.exit(1)
}
