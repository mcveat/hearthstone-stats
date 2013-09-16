package model

import play.api.Play

/**
 * User: mcveat
 */
object Configuration {
  lazy val devEnvironment = Play.current.configuration.getString("env").exists("dev" ==)
}
