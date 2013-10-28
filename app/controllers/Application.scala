package controllers

import play.api.mvc._
import play.modules.reactivemongo._
import play.api.libs.json._
import reactivemongo.bson.BSONObjectID
import model._
import model.JsonFormats._
import play.modules.reactivemongo.json.collection.JSONCollection
import play.api.libs.json.JsObject
import scala.Some
import model.GameResultRequest
import model.Game

object Application extends Controller with MongoController {
  private def collection = db.collection[JSONCollection]("stats")
  
  def index = Action {
    Ok(views.html.index())
  }

  def newStatsPage = Action {
    Async {
      val id = BSONObjectID.generate.stringify
      collection.insert(oid(id)).map { _ =>
        Redirect(routes.Application.stats(id))
      }
    }
  }

  def stats(id: String) = Action {
    Ok(views.html.app(id))
  }

  def heroes = Action {
    def heroJson(h: Hero) = Json.obj(
      "name" -> h.name,
      "imageUrl" -> h.imageUrl,
      "thumbUrl" -> h.thumbUrl
    )
    Ok(Json.toJson( Hero.seq.map(heroJson))).as("application/json")
  }

  def recordGame(id: String) = Action(parse.json) { implicit request =>
    Async {
      val game = request.body.as[GameResultRequest].newGame
      val inc = Seq(
        Some(s"ratios.${game.player.name}.${game.opponent.name}.${game.result.str}" -> 1),
        game.drawing.map { drawing =>
          s"ratios.${game.player.name}.${game.opponent.name}.${drawing.str}.${game.result.str}" -> 1
        }
      )
      val update = Json.obj(
        "$push" -> Json.obj("games" -> game),
        "$inc" -> Json.toJson(inc.flatten.toMap)
      )
      collection.update(oid(id), update).map { _ =>
        Ok(Json.toJson(game)).as("application/json")
      }
    }
  }

  def recentGames(id: String, skip: Option[Int]) = Action {
    Async {
      collection.find(oid(id)).one[JsObject].map { stats =>
        val allGames = stats.flatMap(s => (s \ "games").asOpt[List[Game]]).getOrElse(Seq())
        val (games, rest) = allGames.reverse.drop(skip.getOrElse(0)).splitAt(10)
        val result = Json.obj(
          "games" -> games,
          "hasNext" -> rest.headOption.isDefined
        )
        Ok(Json.toJson(result)).as("application/json")
      }
    }
  }

  def results(id: String) = Action {
    Async {
      collection.find(oid(id)).one[JsObject].map { stats =>
        val ratios = stats.map(_ \ "ratios").getOrElse(Json.obj())
        val games = stats.map(_ \ "games").getOrElse(Json.arr()).as[List[Game]]
        val counts = games.groupBy(_.result).mapValues(_.size).withDefaultValue(0)
        val playerResults = PlayerResults(GamesCount(counts(GameWon), counts(GameDraw), counts(GameLost)), ratios)
        Ok(Json.toJson(playerResults)).as("application/json")
      }
    }
  }

  def reset(id:String) = Action {
    Async {
      val update = Json.obj(
        "$unset" -> Json.obj("games" -> ""),
        "$unset" -> Json.obj("ratios" -> "")
      )
      collection.update(oid(id), update).map(_ => Ok)
    }
  }

  def removeGame(id: String, gameId: String) = Action {
    Async {
      val update = Json.obj(
        "$pull" -> Json.obj(
          "games" -> Json.obj(
            "id" -> gameId
          )
        )
      )
      collection.update(oid(id), update).map(_ => Ok)
    }
  }

  private def oid(id: String) = Json.obj("_id" -> Json.obj("$oid" -> id))
}
