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

require('es6-promise').polyfill()

config =
  slacktesttoken: process.env.HUBOT_ESA_TO_SLACK_SLACKTESTTOKEN
  slackappid: process.env.HUBOT_ESA_TO_SLACK_SLACKAPPID
  slackappsecret: process.env.HUBOT_ESA_TO_SLACK_SLACKAPPSECRET

module.exports = (robot) ->
  channels = {}

  # デバッグ用
  robot.respond /hoge/, (msg) ->
    chid = getChannelId("pj-req-100")
    if chid instanceof Promise
      chid.then (result) ->
        msg.send "channel id is #{result}"
    else
      msg.send "channel id is #{chid}"


  getChannelId = (chname) ->
    url = "https://slack.com/api/channels.list?token=#{config.slacktesttoken}&exclude_archived=1&pretty=1"

    if channels[chname]
      robot.logger.info "#{chname} -> #{channels[chname]}"
      return channels[chname]

    robot.logger.info "Call Slack API"
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
              robot.logger.info "#{c.name} -> #{c.id}"
              channels[c.name] = c.id
              chid = c.id

          if chid == ""
            robot.logger.info "[" + chname + "] not found."

          resolve c.id
          return



  postToChannel = (chid,m_username = "defaultusername",m_text = "defaulttext",m_iconemoji =":+1:") ->
    text = encodeURIComponent(m_text)
    username = encodeURIComponent(m_username)
    iconemoji = encodeURIComponent(m_iconemoji)
    url = "https://slack.com/api/chat.postMessage?token=#{config.slacktesttoken}&channel=#{chid}&text=#{text}&username=#{username}&icon_emoji=#{iconemoji}&pretty=1"

    robot.logger.info "PostToChannel #{url}"

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

  getTagArray = (title) ->
    titlearray = title.split(" ")
    tagarray = []

    for item in titlearray
      m = /^#(\S+)$/.exec(item)
      if m?
        tagarray.push m[1]
    tagarray


  robot.respond /slack/, (msg) ->

    msg.send "slack command received"

    chid = getChannelId("pj-req-100")
    if chid instanceof Promise
      chid.then (result) ->
        msg.send "channel id is #{result}"
        postToChannel(result)
      .then (result) ->
        msg.send "send message completed"
    else
      postToChannel(chid)
      .then (result) ->
        msg.send "send message completed"



  robot.router.post "/esa-to-slack/post", (req, msg) ->

    # robot.logger.info "================"
    # robot.logger.info req.body
    # robot.logger.info "================"

    if not req.body
      robot.logger.info "なにかエラー"
      return

    username = req.body.user.name
    title = req.body.post.name
    message = req.body.post.message
    url = req.body.post.url
    # robot.logger.info username
    # robot.logger.info title
    # robot.logger.info message
    # robot.logger.info url

    robot.logger.info "**************"
    tagarray = getTagArray(title)
    for tag in tagarray
      # タグを見つけたら、タグと同じチャンネル名を探してメッセージを投げる

      chid = getChannelId(tag)
      if chid instanceof Promise
        chid.then (result) ->
          if result == ""
            # robot.logger.info "**************"
          else
            robot.logger.info "channel found. Id : #{result}"
            postToChannel(result)
            .then (result) ->
              robot.logger.info "send message completed"
              # robot.logger.info "**************"
      else
        robot.logger.info "chid = #{chid}"
        if chid == ""
          robot.logger.info "???"
        else
          postToChannel(chid)
          .then (result) ->
            robot.logger.info "send message completed"
            # robot.logger.info "**************"
