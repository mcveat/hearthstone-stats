package model

import controllers.routes
import reactivemongo.bson.BSONObjectID
import java.util.Date

/**
 * User: mcveat
 */
sealed class GameResult(val str: String)
case object GameWon extends GameResult("won")
case object GameDraw extends GameResult("draw")
case object GameLost extends GameResult("lost")
object GameResult {
  def seq = Seq(GameWon, GameDraw, GameLost)
  def apply(s: String) = {
    val lower = s.toLowerCase
    seq.find(lower == _.str)
  }
}

sealed class Hero(val name: String, fileName: String) {
  def imageUrl = routes.Assets.at("images/heroes/%s.jpg".format(fileName)).url
  def thumbUrl = routes.Assets.at("images/heroes/thumbs/%s.jpg".format(fileName)).url
}
case object Druid extends Hero("druid", "malfurion")
case object Hunter extends Hero("hunter", "rexxar")
case object Mage extends Hero("mage", "jaina")
case object Paladin extends Hero("paladin", "uther")
case object Priest extends Hero("priest", "anduin")
case object Rogue extends Hero("rogue", "valeera")
case object Shaman extends Hero("shaman", "thrall")
case object Warlock extends Hero("warlock", "guldan")
case object Warrior extends Hero("warrior", "garrosh")
object Hero {
  def seq = Seq(Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, Warrior)
  def apply(s: String) = {
    val lower = s.toLowerCase
    seq.find(lower == _.name)
  }
}

case class GameResultRequest(player: Hero, opponent: Hero, result: GameResult) {
  def newGame = Game(BSONObjectID.generate.stringify, player, opponent, result, new Date().getTime)
}

case class Game(id: String, player: Hero, opponent: Hero, result: GameResult, at: Long)

object JsonFormats {
  import play.api.libs.json._

  implicit val gameResultReads = new Reads[GameResult] {
    def reads(json: JsValue) = GameResult(json.as[String]).map(JsSuccess(_)).getOrElse(JsError("game result"))
  }
  implicit val gameResultWrites = new Writes[GameResult] {
    def writes(o: GameResult) = JsString(o.str)
  }
  implicit val heroReads = new Reads[Hero] {
    def reads(json: JsValue) = Hero(json.as[String]).map(JsSuccess(_)).getOrElse(JsError("hero"))
  }
  implicit val heroWrites = new Writes[Hero] {
    def writes(o: Hero) = JsString(o.name)
  }
  implicit val gameResultRequestFormat = Json.format[GameResultRequest]
  implicit val gameFormat = Json.format[Game]
}
