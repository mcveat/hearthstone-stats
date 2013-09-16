import sbt._
import Keys._
import play.Project._

object ApplicationBuild extends Build {

  val appName         = "hearthstone-stats"
  val appVersion      = "1.0-SNAPSHOT"

  val appDependencies = Seq(
    // Add your project dependencies here,
    jdbc,
    anorm
  )

  val main = play.Project(appName, appVersion, appDependencies).settings(
    libraryDependencies ++= Seq(
      "org.reactivemongo" %% "play2-reactivemongo" % "0.9"
    ),
    scalacOptions ++= Seq("-feature", "-language:postfixOps")
  )

}
