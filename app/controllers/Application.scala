package controllers

import play.api.mvc._
import play.modules.reactivemongo._
import play.modules.reactivemongo.json.collection.JSONCollection
import play.api.libs.json._
import reactivemongo.bson.BSONObjectID

object Application extends Controller with MongoController {
  private def collection = db.collection[JSONCollection]("stats")
  
  def index = Action {
    Ok(views.html.index())
  }

  def newStatsPage = Action {
    Async {
      val id = BSONObjectID.generate.stringify
      val obj = Json.obj(
        "_id" -> Json.obj(
          "$oid" -> id
        )
      )
      collection.insert(obj).map { _ =>
        Redirect(routes.Application.stats(id))
      }
    }
  }

  def stats(id: String) = Action {
    Ok(views.html.stats())
  }
}
