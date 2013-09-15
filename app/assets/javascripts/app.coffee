battleModule = angular.module('hs-battle', ['restangular'])

battleModule.controller 'MatchResultCtrl', ($scope, Restangular) ->
  $scope.heroes = [
    {
      name : 'Druid'
      imgUrl : '/assets/images/malfurion.jpg'
    },{
      name : 'Hunter'
      imgUrl : '/assets/images/rexxar.jpg'
    },{
      name : 'Mage'
      imgUrl : '/assets/images/jaina.jpg'
    },{
      name : 'Paladin'
      imgUrl : '/assets/images/uther.jpg'
    },{
      name : 'Priest'
      imgUrl : '/assets/images/anduin.jpg'
    },{
      name : 'Rogue'
      imgUrl : '/assets/images/valeera.jpg'
    },{
      name : 'Shaman'
      imgUrl : '/assets/images/thrall.jpg'
    },{
      name : 'Warlock'
      imgUrl : '/assets/images/guldan.jpg'
    },{
      name : 'Warrior'
      imgUrl : '/assets/images/garrosh.jpg'
    }
  ]

  $scope.setPlayersHero = (hero) ->
    $scope.playersHero = hero
  $scope.setOpponentsHero = (hero) ->
    $scope.opponentsHero = hero
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

  postBattleResult = (result) ->
    battle =
      player : $scope.playersHero.name
      opponent : $scope.opponentsHero.name
      result : result
    Restangular.one('stats', $scope.accountId).post('game', battle).then(
      (-> console.log 'success'),
      (-> console.log 'failure')
    )

