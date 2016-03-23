import Player from "./player"

let Video = {
  init(socket, element) {
    if (!element) { return }
    let playerId = element.getAttribute("data-player-id")
    let videoId = element.getAttribute("data-id")
    socket.connect()
    Player.init(element.id, playerId, () =>{
      this.onReady(videoId, socket)
    })
  },
  onReady(videoId, socket){
    let msgContainer = document.getElementById("msg-container")
    let msgInput = document.getElementById("msg-input")
    let postButton = document.getElementById("msg-submit")
    let vidChannel = socket.channel("videos:" + videoId)
    postButton.addEventListener("click", e => {
      let payload = { body: msgInput.value, at: Player.getCurrentTime()}
      vidChannel.push("new_annotation", payload)
        .receive("error", e => console.log(e))
      msgInput.value = ""
    })

    vidChannel.on("new_annotation", (resp) => {
      vidChannel.params.last_seen_id = resp.id
      this.renderAnnotation(msgContainer, resp)
    })

    msgContainer.addEventListener("click", e => {
      e.preventDefault()
      let seconds = e.target.getAttribute("data-seek") || e.target.parentNode.getAttribute("data-seek")
      if(!seconds) { return }
      Player.seekTo(seconds)
    })

    vidChannel.join()
      .receive("ok", ({annotations}) => {
        let ids = annotations.map(ann => ann.id)
        vidChannel.params.last_seen_id = Math.max(...ids)
        this.scheduleMessages(msgContainer, annotations)
      })
      .receive("error", resp => console.log("join failed", resp))
  },

  scheduleMessages(msgContainer, annotations){
    setTimeout(() => {
      let playerTime = Player.getCurrentTime()
      let remaining = this.renderAtTime(annotations, playerTime, msgContainer)
      console.log(`Time: ${playerTime} Remaining: ${remaining}`)
      this.scheduleMessages(msgContainer, remaining)
    }, 1000)
  },

  renderAtTime(annotations, seconds, msgContainer){
    return annotations.filter( ann => {
      if(ann.at > seconds) {
        return true
      } else {
        this.renderAnnotation(msgContainer, ann)
        return false
      }
    })
  },

  esc(str) {
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  renderAnnotation(msgContainer, {user, body, at}) {
    // TODO append annotation to msgContainer's children
    let template = document.createElement("div")
    template.innerHTML = `
      <a href="#" data-seek="${this.esc(at)}">
        [${this.formatTime(at)}]
        <b>${this.esc(user.username)}</b>: ${this.esc(body)}
      </a>
    `
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  },

  formatTime(millis) {
    let date = new Date(null)
    date.setSeconds(millis/1000)
    return date.toISOString().substr(14, 5)
  }
}
export default Video
