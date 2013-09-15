battleModule = angular.module('hs-battle', ['restangular'])

battleModule.controller 'MatchResultCtrl', ($scope, Restangular) ->
  $scope.init = (id) ->
    $scope.statsBase = Restangular.one('stats', id)
    $scope.statsBase.all('games').getList().then (games) -> $scope.games = games
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

  $scope.fromNow = (timestamp) -> moment(timestamp).fromNow()


  postBattleResult = (result) ->
    battle =
      player : $scope.playersHero.name
      opponent : $scope.opponentsHero.name
      result : result
    $scope.statsBase.post('game', battle).then(
      ( (game) ->
        console.log $scope.games
        $scope.games.unshift game ),
      ( -> $scope.alerts.push
          type: 'danger'
          msg: 'Failed to submit game results. Try again?'
      )
    )
