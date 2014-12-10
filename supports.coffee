angular.module('Supports',['ui.router', 'ui.bootstrap', 'checklistModel'])
.config ['$stateProvider', ($stateProvider) ->
  $stateProvider
    .state 'items',
      url: ''
      templateUrl: 'supports.html'
      controller: 'SupportsController'
      resolve:
        items: ['$http', ($http) ->
          $http.get('/admin/support.json').then (response)->
            return response.data
        ]
]
.run( -> console.log('running'))
.controller 'SupportsController', ['$scope','items', '$rootScope', '$http'
, ($scope, items, $rootScope, $http) ->

    sortByKey = (array, key) ->
      array.sort (a, b) ->
        x = a[key]
        y = b[key]
        (if (x < y) then -1 else ((if (x > y) then 1 else 0)))
    $scope.selected = [];
    supports = items.supports
    cdevs = sortByKey(items.users,'name')
    $scope.cdevs = cdevs
    $scope.Math = window.Math
    $scope.start = 0
    limit = $scope.limit = 25
    page = 1
    start = $scope.start
    $scope.supports = supports

    $scope.fil_supp = supports

    $scope.SearchSupports = (text) ->
      if text.length > 0
        $scope.fil_supp = _.filter($scope.supports, (obj) ->
          (obj.title?.toLowerCase().indexOf(text.toLowerCase()) > -1))

      else
        $scope.fil_supp = supports.slice(start , start + limit)

    $scope.total = $scope.fil_supp.length
    updateList = ->
      $scope.fil_supp = supports.slice(start , start + limit)
      $scope.start = start

    $scope.nextPage = ->
      page++
      start = (page - 1) * limit
      updateList()
    $scope.prevPage = ->
      page--
      start = (page - 1) * limit
      updateList()
    $rootScope.firstPage = ->
      page = 1
      start = 0
      updateList()

    start = $scope.start = (page - 1) * limit || 0
    $scope.$watchCollection 'filteredSupports', updateList
    $scope.delete = ->
      if $scope.selected.length == 0
        confirm('Please select supports!')
      else
        ids = (" #{support.title}" for support in $scope.selected)
        if confirm("Delete supports: #{ids}?")
          ids = _.pluck($scope.selected,"id")
          $http.post('/admin/support/bulk_delete', {ids:ids})
          window.location.reload(false)
    ###
    alreadyAssigned = (ids) ->
      console.log('looking for assignements')
      already_assigned = ($http,ids) ->
      $http.get('/admin/support/already_assigned.json', ids).then (response)->
        return response.data
      console.log(already_assigned)
      return already_assigned
    ###

    $scope.assign = ->
      assignment = document.getElementById("assignmentSelect");
      assignment = assignment.options[assignment.selectedIndex].value
      if $scope.selected.length == 0
        confirm('Please select supports!')
      else if assignment == '-- Pick a user --'
        alert('Please select a user to assign to!')
      else
        ids = (" #{support.title}" for support in $scope.selected)
        assignment = JSON.parse(assignment)
        ids = _.pluck($scope.selected,"id")
        #a_assigned = alreadyAssigned(ids)
        #if a_assigned.length > 0
        #  if confirm("Some of those supports have already been assigned, are you sure you want to assign them?")
        #    $http.post('/admin/support/assign', {ids:ids, user_id:assignment.id})
        #    alert('Supports successfully assigned')
        #else
        if confirm("Assign the following supports to #{assignment.name}: #{ids}?")
          $http.post('/admin/support/assign', {ids:ids, user_id:assignment.id})
          alert('Supports successfully assigned')
]


.controller 'FilterController', ['CollectionFilter', 'query', '$scope', 'supports'
, (CollectionFilter, query, $scope, supports) ->
    $scope.query = query
    filterSupports = ->
      for criterion in criteria
        criterion.values = query[criterion.key]
      $scope.filteredSupports = cachedQueries[JSON.stringify(query)] ||= CollectionFilter(supports, criteria)
    watchQuery = (newVal, oldVal) ->
      return if newVal is oldVal
      filterSupports()
    for keys, v of query
      if(_.isArray(v))
        $scope.$watchCollection "query.#{keys}", watchQuery
      else
        $scope.$watch "query['#{keys}']", watchQuery
    filterSupports()
]
.controller 'FilterController', ['$scope', 'query', ($scope, query) ->
  $scope.criteria = criteria
  $scope.query = query
]
