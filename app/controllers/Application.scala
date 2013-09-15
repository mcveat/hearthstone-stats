package controllers

import play.api.mvc._
import play.modules.reactivemongo._
import play.modules.reactivemongo.json.collection.JSONCollection
import play.api.libs.json._
import reactivemongo.bson.BSONObjectID
import model.GameResultRequest
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

  def recordGame(id: String) = Action(parse.json) { implicit request =>
    Async {
      val game = request.body.as[GameResultRequest].newGame
      val update = Json.obj("$push" -> Json.obj("games" -> game))
      collection.update(oid(id), update).map { _ =>
        Ok(Json.toJson(game)).as("application/json")
      }
    }
  }

  private def oid(id: String): JsObject = {
    Json.obj("_id" -> Json.obj("$oid" -> id))
  }
}
