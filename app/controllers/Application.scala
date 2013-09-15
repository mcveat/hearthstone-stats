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
    Ok(views.html.stats(id))
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
      val update = Json.obj("$push" -> Json.obj("games" -> game))
      collection.update(oid(id), update).map { _ =>
        Ok(Json.toJson(game)).as("application/json")
      }
    }
  }

  def recentGames(id: String) = Action {
    Async {
      collection.find(oid(id)).one[JsObject].filter(_.isDefined).map(_.get).map { stats =>
        val games = (stats \ "games").as[List[Game]]
        Ok(Json.toJson(games.reverse.take(10))).as("application/json")
      }
    }
  }

  private def oid(id: String): JsObject = {
    Json.obj("_id" -> Json.obj("$oid" -> id))
  }
}
