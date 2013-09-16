package controllers

import play.api.mvc._
import play.modules.reactivemongo._
import play.modules.reactivemongo.json.collection.JSONCollection
import play.api.libs.json._
import reactivemongo.bson.BSONObjectID
import model.{Game, Hero, GameResultRequest}
import model.JsonFormats._

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
      "imageUrl" -> h.imageUrl
    )
    Ok(Json.toJson( Hero.seq.map(heroJson))).as("application/json")
  }

  def recordGame(id: String) = Action(parse.json) { implicit request =>
    Async {
      val game = request.body.as[GameResultRequest].newGame
      val update = Json.obj(
        "$push" -> Json.obj("games" -> game),
        "$inc" -> Json.obj(
          s"ratios.${game.player.name}.${game.opponent.name}.${game.result.str}" -> 1
        )
      )
      collection.update(oid(id), update).map { _ =>
        Ok(Json.toJson(game)).as("application/json")
      }
    }
  }

  def recentGames(id: String) = Action {
    Async {
      collection.find(oid(id)).one[JsObject].map { stats =>
        val games = stats.flatMap(s => (s \ "games").asOpt[List[Game]]).getOrElse(Seq())
        Ok(Json.toJson(games.reverse.take(10))).as("application/json")
      }
    }
  }

  private def oid(id: String) = Json.obj("_id" -> Json.obj("$oid" -> id))
}
