# Description
#   A hubot script that does the things
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   naichilab <naichilab@live.jp>

config =
  slacktesttoken: process.env.HUBOT_ESA_TO_SLACK_SLACKTESTTOKEN
  slackappid: process.env.HUBOT_ESA_TO_SLACK_SLACKAPPID
  slackappsecret: process.env.HUBOT_ESA_TO_SLACK_SLACKAPPSECRET

module.exports = (robot) ->

  getChannelId = (chname) ->
    url = "https://slack.com/api/channels.list?token=#{config.slacktesttoken}&exclude_archived=1&pretty=1"

    new Promise (resolve) ->
      robot.http(url)
        .get() (err, res, body) ->
          if err
            robot.logger.error err
            resolve ""
            return

          data = JSON.parse body

          if !data.ok
            robot.logger.error data.error
            resolve ""
            return

          chid = ""
          for c in data.channels
            if c.name == chname
              robot.logger.info "[#{c.id}]#{c.name} found."
              resolve c.id
              return

          robot.logger.info "[" + chname + "] is not found."
          resolve ""
          return

  postToChannel = (chid) ->
    text = encodeURIComponent("this is message")
    username = encodeURIComponent("usernameあいうえお")
    iconemoji = encodeURIComponent(":+1:")
    url = "https://slack.com/api/chat.postMessage?token=#{config.slacktesttoken}&channel=#{chid}&text=#{text}&username=#{username}&icon_emoji=#{iconemoji}&pretty=1"

    new Promise (resolve) ->
      robot.http(url)
        .get() (err, res, body) ->
          if err
            robot.logger.error err
            resolve ""
            return

          data = JSON.parse body

          if !data.ok
            robot.logger.error data.error
            resolve ""
            return

          robot.logger.info "post message success"
          resolve ""
          return

  robot.respond /slack/, (msg) ->
    msg.send "A"

    getChannelId "pj-req-100"
    .then (result) ->
      msg.send "B"
      postToChannel (result)
    .then (result) ->
      msg.send "C"

  robot.router.post "/esa-to-slack/post", (req, res) ->
    if not req.body
      res.end ""
      return

    room_name = req.body.room
    message = req.body.message

    room_name = "random" unless room_name

    robot.send {room: room_name}, message
    res.end "send #{room_name} #{message}"
