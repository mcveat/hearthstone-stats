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

  $scope.setDrawing = (state) ->
    if $scope.drawing != state then $scope.drawing = state
    else $scope.drawing = null

  postBattleResult = (result) ->
    battle =
      player : $scope.playersHero.name
      opponent : $scope.opponentsHero.name
      result : result
      drawing : $scope.drawing
    $scope.statsBase.post('game', battle).then(
      ( (game) -> $scope.gameList.games.unshift game ),
      ( -> $scope.alerts.push
          type: 'danger'
          msg: 'Failed to submit game results. Try again?'
      )
    )

app.controller 'StatsCtrl', ($scope, Restangular) ->
  $scope.init = (id) ->
    Restangular.one('stats', id).customGET('results').then (results) ->
      $scope.results = results.stats
      $scope.summary = calculateSummary(results.games)
    Restangular.all('heroes').getList().then (heroes) ->
      $scope.heroes = heroes
      $scope.heroRows = _.chain(heroes).groupBy((hero, index) -> Math.floor(index/3)).toArray().value()

  $scope.setDrawing = (state) ->
    if $scope.drawing != state then $scope.drawing = state
    else $scope.drawing = null

  $scope.statsOf = (hero) ->
    if !$scope.heroes? or !$scope.results? then return []

    stats =
      $$hashKey : 1
      overall : getOverallStats hero
      matchups : getMatchupsFor hero

    [stats]

  getOverallStats = (hero) ->
    overallMatchups = getOverallMatchups(hero)
    numberOfOverallMatchups = getNumberOfMatches(overallMatchups)
    winRatio = getOverallRatio(overallMatchups, numberOfOverallMatchups)

    overallAgainstMatchups = getOverallAgainstMatchups(hero)
    numberOfOverallAgainstMatchups = getNumberOfMatches(overallAgainstMatchups)
    winAgainstRatio = getOverallRatio(overallAgainstMatchups, numberOfOverallAgainstMatchups)

    matches : numberOfOverallMatchups ? 0
    winRatio : winRatio?.toFixed(2) ? 'N/A'
    matchesColor : getColorFor(winRatio)
    matchesAgainst : numberOfOverallAgainstMatchups ? 0
    winAgainstRatio : winAgainstRatio?.toFixed(2) ? 'N/A'
    matchesAgainstColor : getColorFor(winAgainstRatio)

  getMatchupsFor = (hero) -> _.chain($scope.heroes).map((h) -> [h.name, getMatchup(hero, h.name)]).object().value()

  getMatchup = (player, opponent) ->
    matchup = $scope.results?[player]?[opponent]
    if $scope.drawing? then matchup = matchup?[$scope.drawing]
    win = matchup?.won ? 0
    games = getGames(matchup)
    ratio = if games > 0 then win / games * 100 else null

    win : win
    draw : matchup?.draw ? 0
    lost : matchup?.lost ? 0
    ratio : ratio?.toFixed(2) ? 'N/A'
    color : getColorFor(ratio)

  getOverallMatchups = (hero) ->
    results = $scope.results?[hero]
    if !results? then return null
    matchups = _.values(results)
    if $scope.drawing? then matchups = _.pluck(matchups, $scope.drawing)
    matchups

  getOverallAgainstMatchups = (hero) ->
    if !$scope.results? then return null
    matchups = _.chain($scope.results).values().filter((m) -> _.has(m, hero)).pluck(hero).value()
    if $scope.drawing? then matchups = _.pluck(matchups, $scope.drawing)
    matchups

  getNumberOfMatches = (matchups) ->
    _.chain(matchups).map((m) -> getGames(m)).reduce(((sum, e) -> sum + e), 0).value()

  getOverallRatio = (matchups, overall) ->
    if overall == 0 then return null
    win = _.chain(matchups).map((m) -> m?.won ? 0).reduce(((sum, e) -> sum + e), 0).value()
    win / overall * 100

  rainbow = new Rainbow()
  rainbow.setSpectrum('#FFBEBE', '#8DE28D')
  $scope.rainbow = rainbow

  getColorFor = (ratio) ->
    if !ratio? then return "#FFFFFFFF"
    "##{$scope.rainbow.colourAt(ratio)}"

  calculateSummary = (games) ->
    all = _.chain(games).values().reduce(((sum, e) -> sum + e), 0).value()
    _.chain(games).pairs().map( (pair) ->
      [result, count] = pair
      percentage = if count == 0 then 0 else count / all * 100
      [result,
        count: count
        percentage: percentage.toFixed(2)
        color: getColorFor(percentage)
      ]
    ).object().value()

  getGames = (matchup) -> _.chain(matchup).omit('first', 'second').values().reduce(((sum, e) -> sum + e), 0).value()
