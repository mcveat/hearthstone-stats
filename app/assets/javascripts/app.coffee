root = exports ? this

root.MatchResultCtrl = ($scope) ->
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

  $scope.setPlayersHero = (hero) -> $scope.playersHero = hero
  $scope.setOpponentsHero = (hero) -> $scope.opponentsHero = hero
