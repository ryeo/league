LeagueRouter = FilteredRouter.extend
  initialize: ->
    FilteredRouter.prototype.initialize.call(this)
    @filter @require_login, {except: ['home', 'loading', 'logo_tester']}
    @filter @close_overlays, {except: ['games']}
  
  require_login: (page, logged_out_page = 'signin', loading_page = 'loading') ->
    # we are logged in AND the data has loaded from the server
    if not Meteor.user() 
      logged_out_page
    else if Meteor.user().loading
      loading_page
    else
      page
  
  close_overlays: (page) ->
    close_overlays()
    page

  routes: 
    '': 'home'
    'leagues': 'leagues'
    'logo_tester': 'logo_tester'
    ':team_id': 'players'
    ':team_id/season': 'games'
    ':team_id/origami': 'origami'
  
  logo_tester: -> @goto('logo_tester')
  origami: (team_id) ->
    Session.set 'team_id', team_id
    @goto('origami')
    
  home: -> 
    @goto => @require_login('teams', 'home', 'loading')
  
  leagues: -> @goto('teams')
  players: (team_id) ->
    Session.set 'team_id', team_id
    @goto('players')
  games: (team_id) -> 
    Session.set 'team_id', team_id
    
    # outside of the goto so it only happens once
    if Session.get('opening_status_overlay')
      Session.set('opening_status_overlay', false)
    else
      close_overlays()
    
    @goto =>
      # if they are logged in but there's no team, we may need to join the team
      if current_player() and not current_team()
        if (document.location.hash == '#season-ticket') and not Session.get('team_id_invalid')
          Meteor.call 'join_team', current_player().id, team_id, (error, joined) ->
            # something's wrong with this team
            Session.set('team_id_invalid', true) unless joined
          
          # show loading in the meantime
          return 'loading'
        
      # otherwise, standard logic
      @require_login('games', 'signin', 'loading')

Router = new LeagueRouter
Transitioner.instance = new Transitioner()

Meteor.startup ->
  Backbone.history.start({pushState: true})
  Transitioner.instance.init(Router)
  
