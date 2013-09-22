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
    Restangular.one('stats', id).customGET('results').then (results) -> $scope.results = results
    Restangular.all('heroes').getList().then (heroes) ->
      $scope.heroes = heroes
      $scope.heroRows = _.chain(heroes).groupBy((hero, index) -> Math.floor(index/3)).toArray().value()

  $scope.value = (player, opponent, result) -> getMatchup(player, opponent)?[result] ? 0

  $scope.winPercentage = (player, opponent) ->
    matchup = getMatchup(player, opponent)
    if !matchup? then return "N/A"
    "#{getMatchupWinRatio(matchup).toFixed(2)}"

  rainbow = new Rainbow()
  rainbow.setSpectrum('#FFBEBE', '#8DE28D')
  $scope.rainbow = rainbow

  $scope.getColorFor = (player, opponent) ->
    matchup = getMatchup(player, opponent)
    if !matchup? then return "#FFFFFFFF"
    "##{$scope.rainbow.colourAt(getMatchupWinRatio(matchup))}"

  $scope.setDrawing = (state) ->
    if $scope.drawing != state then $scope.drawing = state
    else $scope.drawing = null

  $scope.getOverallWinRatio = (hero) ->
    ratio = getOverallRatio($scope.getOverallMatchups(hero))
    if !ratio? then return 'N/A'
    ratio.toFixed(2)

  $scope.getOverallMatchups = (hero) ->
    results = $scope.results?[hero]
    if !results? then return null
    matchups = _.values(results)
    if $scope.drawing? then matchups = _.pluck(matchups, $scope.drawing)
    matchups

  $scope.getOverallWinAgainstRatio = (hero) ->
    ratio = getOverallRatio($scope.getOverallAgainstMatchups(hero))
    if !ratio? then return 'N/A'
    ratio.toFixed(2)

  $scope.getOverallAgainstMatchups = (hero) ->
    if !$scope.results? then return null
    matchups = _.chain($scope.results).values().filter((m) -> _.has(m, hero)).pluck(hero).value()
    if $scope.drawing? then matchups = _.pluck(matchups, $scope.drawing)
    matchups

  $scope.getNumberOfMatchesPlayed = (hero) ->
    getNumberOfMatches($scope.getOverallMatchups(hero))

  $scope.getNumberOfMatchesPlayedAgainst = (hero) ->
    getNumberOfMatches($scope.getOverallAgainstMatchups(hero))

  $scope.getColorForOverall = (matchups) ->
    ratio = getOverallRatio(matchups)
    if !ratio? then return "#FFFFFFFF"
    "##{$scope.rainbow.colourAt(ratio)}"

  getOverallRatio = (matchups) ->
    overall = getNumberOfMatches(matchups)
    if overall == 0 then return null
    win = _.chain(matchups).map((m) -> m?.won ? 0).reduce(((sum, e) -> sum + e), 0).value()
    win / overall * 100

  getNumberOfMatches = (matchups) ->
    _.chain(matchups).map((m) -> getGames(m)).reduce(((sum, e) -> sum + e), 0).value()

  getMatchup = (player, opponent) ->
    matchup = $scope.results?[player]?[opponent]
    if $scope.drawing? then matchup = matchup?[$scope.drawing]
    matchup

  getGames = (matchup) -> _.chain(matchup).omit('first', 'second').values().reduce(((sum, e) -> sum + e), 0).value()

  getMatchupWinRatio = (matchup) -> (matchup.won ? 0) / getGames(matchup) * 100
