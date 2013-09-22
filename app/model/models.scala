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

sealed class Drawing(val str: String)
case object First extends Drawing("first")
case object Second extends Drawing("second")
object Drawing {
  def seq = Seq(First, Second)
  def apply(s: String) = {
    val lower = s.toLowerCase
    seq.find(lower == _.str)
  }
}

case class GameResultRequest(player: Hero, opponent: Hero, result: GameResult, drawing: Option[Drawing]) {
  def newGame = Game(BSONObjectID.generate.stringify, player, opponent, result, new Date().getTime, drawing)
}

case class Game(id: String, player: Hero, opponent: Hero, result: GameResult, at: Long, drawing: Option[Drawing])

object JsonFormats {
  import play.api.libs.json._

  implicit val gameResultReads = new Format[GameResult] {
    def reads(json: JsValue) = GameResult(json.as[String]).map(JsSuccess(_)).getOrElse(JsError("game result"))
    def writes(o: GameResult) = JsString(o.str)
  }
  implicit val heroReads = new Format[Hero] {
    def reads(json: JsValue) = Hero(json.as[String]).map(JsSuccess(_)).getOrElse(JsError("hero"))
    def writes(o: Hero) = JsString(o.name)
  }
  implicit val drawingReads = new Format[Drawing] {
    def reads(json: JsValue) = Drawing(json.as[String]).map(JsSuccess(_)).getOrElse(JsError("drawing state"))
    def writes(o: Drawing) = JsString(o.str)
  }
  implicit val gameResultRequestFormat = Json.format[GameResultRequest]
  implicit val gameFormat = Json.format[Game]
}
