// Configuration file for Tournament Manager admin panel

const CONFIG = {
  // API endpoints (relative to base URL)
  endpoints: {
    tournament: '/turnier/create',
    qualification: '/turnier/start-qualification',
    ageGroups: '/agegroups',
    teams: '/teams',
    pitches: '/pitches',
    rounds: '/rounds',
    stats: '/stats',
    reporting: '/reporting'
  },

  // Get full API URL for an endpoint
  getApiUrl: function(endpoint) {
    return BASE_API_URL + (this.endpoints[endpoint] || endpoint);
  }
};
