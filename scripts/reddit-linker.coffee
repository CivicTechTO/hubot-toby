# Description:
#   Watch for links and search for reddit posts about them.
#   If they exist, the top 2 most commented threads are linked.
#
# Configuration:
#   HUBOT_REDDIT_USERNAME
#   HUBOT_REDDIT_PASSWORD
#   HUBOT_REDDIT_APP_ID
#   HUBOT_REDDIT_APP_SECRET
#
# Author:
#   patcon@github

getUrls = require 'get-urls'
snoowrap = require 'snoowrap'
_ = require 'underscore'

config =
  username: process.env.HUBOT_REDDIT_USERNAME
  password: process.env.HUBOT_REDDIT_PASSWORD
  app_id: process.env.HUBOT_REDDIT_APP_ID
  app_secret: process.env.HUBOT_REDDIT_APP_SECRET

URL_REGEXP = /((https?|ftp):\/\/|www\.)[^\s\/$.?#].[^\s]*/i

module.exports = (robot) ->
  robot.listen(
    (message) ->
      if typeof(message.text) == 'string'
        getUrls(message.text).size > 0
    (res) ->
      client = new snoowrap(
        userAgent: 'github.com/civictechto/hubot-toby',
        clientId: config.app_id,
        clientSecret: config.app_secret,
        username: config.username,
        password: config.password,
      )

      sayResults = (data) ->
        if data.length > 0
          res.send "Yay! I found some Reddit conversations about the link shared above."
          for d in _.sortBy(data, (datum) -> datum.num_comments ).reverse().slice(0, 2)
            res.send "https://www.reddit.com#{d.permalink}"

      # Reddit matching is very specific, so don't want to mangle too much.
      # See: https://github.com/sindresorhus/normalize-url
      urlNormalizationOpts =
        normalizeProtocol: false,
        removeTrailingSlash: false,
        stripWWW: false,

      for url in Array.from(getUrls(res.message.text, urlNormalizationOpts))
        console.log url
        client._get({uri: 'api/info', qs:{url: url}})
          .then(sayResults)
          .catch(console.error)
  )

