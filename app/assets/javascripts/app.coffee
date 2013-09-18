app = angular.module('hs', ['restangular'])

app.config ($routeProvider) ->
  $routeProvider
    .when('/game', { controller : 'MatchResultCtrl', templateUrl : 'game.html'})
    .when('/stats', { controller : 'StatsCtrl', templateUrl : 'stats.html'})
    .when('/about', { templateUrl : 'about.html'} )
    .otherwise redirectTo : '/game'

app.controller 'MenuCtrl', ($scope, $location) ->
  $scope.path = $location.path()
  $scope.setTab = (path) ->
    $scope.path = path
    $location.path path

app.controller 'MatchResultCtrl', ($scope, Restangular) ->
  $scope.init = (id) ->
    $scope.statsBase = Restangular.one('stats', id)
    $scope.statsBase.customGET('games').then (gameList) -> $scope.gameList = gameList
    Restangular.all('heroes').getList().then (heroes) -> $scope.heroes = heroes

  $scope.alerts = []

  $scope.setPlayersHero = (hero) -> $scope.playersHero = hero
  $scope.setOpponentsHero = (hero) -> $scope.opponentsHero = hero
  $scope.readyToBattle = -> $scope.playersHero? && $scope.opponentsHero?

  $scope.markBattleAsWon = ->
    if !$scope.readyToBattle() then return
    postBattleResult('won')

  $scope.markBattleAsDraw = ->
    if !$scope.readyToBattle() then return
    postBattleResult('draw')

  $scope.markBattleAsLost = ->
    if !$scope.readyToBattle() then return
    postBattleResult('lost')

  $scope.closeAlert = (index) -> $scope.alerts.splice(index, 1)

  $scope.getHeroImageUrl = (name) ->
    hero = _.find($scope.heroes, (h) -> h.name == name)
    hero?.imageUrl

  $scope.getHeroThumbUrl = (name) ->
    hero = _.find($scope.heroes, (h) -> h.name == name)
    hero?.thumbUrl

  $scope.fromNow = (timestamp) -> moment(timestamp).fromNow()

  $scope.reset = () ->
    $scope.statsBase.remove().then(
      (-> $scope.gameList.games = []),
      ( -> $scope.alerts.push
        type: 'danger'
        msg: 'Failed to clean games history. Try again?'
      )
    )
    $('#reset-confirm-modal').modal('hide')

  $scope.removeGame = (id) ->
    $scope.statsBase.one('game', id).remove().then(
      (-> $scope.gameList.games = _.reject $scope.gameList.games, (g) -> g.id == id),
      ( -> $scope.alerts.push
        type: 'danger'
        msg: 'Failed to clean games history. Try again?'
      )
    )

  $scope.nextGames = ->
    $scope.statsBase.customGET('games', 'skip' : $scope.gameList.games.length).then (gamesList) ->
      $scope.gameList.games = $scope.gameList.games.concat(gamesList.games)
      $scope.gameList.hasNext = gamesList.hasNext

  postBattleResult = (result) ->
    battle =
      player : $scope.playersHero.name
      opponent : $scope.opponentsHero.name
      result : result
    $scope.statsBase.post('game', battle).then(
      ( (game) -> $scope.gameList.games.unshift game ),
      ( -> $scope.alerts.push
          type: 'danger'
          msg: 'Failed to submit game results. Try again?'
      )
    )

app.controller 'StatsCtrl', ($scope, Restangular) ->
  $scope.init = (id) ->
    Restangular.one('stats', id).customGET('results').then (results) -> $scope.results = results
    Restangular.all('heroes').getList().then (heroes) ->
      $scope.heroes = heroes
      $scope.heroRows = _.chain(heroes).groupBy((hero, index) -> Math.floor(index/3)).toArray().value()
  $scope.value = (player, opponent, result) -> $scope.results?[player]?[opponent]?[result] ? 0
  $scope.winPercentage = (player, opponent) ->
    matchup = $scope.results?[player]?[opponent]
    if !matchup? then return "N/A"
    overall = _.chain(matchup).values().reduce((sum, e) -> sum + e).value()
    wins = matchup['won'] ? 0
    "#{(wins / overall * 100).toFixed(2)} %"
