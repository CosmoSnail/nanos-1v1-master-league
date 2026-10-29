/* =====================================================
   BROWSER PREVIEW
   Outside the game there is no Events: a stand-in, so the
   HUD can be worked on in a browser with emit('Event', ...)
===================================================== */
if (typeof Events === 'undefined') {
  const handlers = {}
  window.Events = {
    Subscribe: (name, fn) => (handlers[name] = handlers[name] || []).push(fn),
    Call: () => {},
  }
  window.emit = (name, ...args) => (handlers[name] || []).forEach((fn) => fn(...args))
}

/* =====================================================
   HUD REFERENCES (DOM CACHE)
   Cache all static DOM references once
===================================================== */
const timerEl = document.querySelector('#timer')

const teamAScoreEl = document.querySelector('#team-a-score')
const teamBScoreEl = document.querySelector('#team-b-score')
const timerContainerEl = document.querySelector('#timer-container')

const countdownOverlayEl = document.querySelector('#countdown-overlay')
const countdownNumberEl = document.querySelector('#countdown-number')

const leaderboardScoreAEl = document.querySelector('#leaderboard-score-a')
const leaderboardScoreBEl = document.querySelector('#leaderboard-score-b')

const TEAM_NAMES = { 1: 'WITCHES', 2: 'SKELETONS' }

/* =====================================================
   HUD STATE MACHINE
   Controls which UI elements should be visible / active
===================================================== */
const HUD_STATE = {
  NORMAL: 'normal',
  GOAL: 'goal',
  COUNTDOWN: 'countdown',
  ENDED: 'ended',
}

let currentHudState = HUD_STATE.NORMAL

/**
 * Sets the current HUD state
 * Responsible only for HUD visibility / scale
 */
function setHudState(state) {
  currentHudState = state

  switch (state) {
    case HUD_STATE.NORMAL:
      gsap.to(timerContainerEl, {
        opacity: 1,
        scale: 1,
        duration: 0.3,
        ease: 'power3.out',
      })
      break

    case HUD_STATE.GOAL:
      gsap.to(timerContainerEl, {
        opacity: 0,
        scale: 0.9,
        duration: 0.25,
        ease: 'power2.out',
      })
      break

    case HUD_STATE.COUNTDOWN:
    case HUD_STATE.ENDED:
      gsap.to(timerContainerEl, {
        opacity: 0,
        scale: 0.95,
        duration: 0.25,
        ease: 'power2.out',
      })
      break
  }
}

/* =====================================================
   BATS
   A flock crossing the top of the screen now and then,
   and a burst of them out of the goal banner
===================================================== */
const hudBatsEl = document.querySelector('#hud-bats')

function spawnBat(from, to, duration, size, delay) {
  const bat = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  bat.setAttribute('class', 'hud-bat')
  bat.innerHTML = '<use href="#icon-bat" />'
  bat.style.width = `${size}px`
  bat.style.height = `${size * 0.47}px`
  bat.style.animationDuration = `${0.14 + Math.random() * 0.08}s`
  hudBatsEl.appendChild(bat)

  gsap.set(bat, { x: from.x, y: from.y, opacity: 0 })
  gsap
    .timeline({ delay, onComplete: () => bat.remove() })
    .to(bat, { opacity: 1, duration: 0.2 })
    .to(bat, { x: to.x, duration, ease: 'none' }, 0)
    .to(
      bat,
      {
        y: to.y,
        duration,
        ease: `sine.inOut`,
      },
      0
    )
    .to(bat, { opacity: 0, duration: 0.3 }, duration - 0.3)
}

function batFlock() {
  const w = window.innerWidth
  const h = window.innerHeight
  const leftToRight = Math.random() < 0.5
  const count = 3 + Math.floor(Math.random() * 4)
  const baseY = h * (0.08 + Math.random() * 0.22)
  for (let i = 0; i < count; i++) {
    const y = baseY + (Math.random() - 0.5) * 120
    spawnBat(
      { x: leftToRight ? -80 : w + 80, y },
      { x: leftToRight ? w + 80 : -80, y: y + (Math.random() - 0.5) * 160 },
      5 + Math.random() * 3,
      26 + Math.random() * 22,
      i * 0.25 + Math.random() * 0.4
    )
  }
}

function batBurst() {
  const w = window.innerWidth
  const h = window.innerHeight
  for (let i = 0; i < 16; i++) {
    const angle = Math.random() * Math.PI * 2
    const reach = Math.max(w, h)
    spawnBat(
      { x: w / 2 + (Math.random() - 0.5) * 400, y: h / 2 + (Math.random() - 0.5) * 120 },
      { x: w / 2 + Math.cos(angle) * reach, y: h / 2 + Math.sin(angle) * reach * 0.6 },
      1.6 + Math.random() * 1.2,
      34 + Math.random() * 30,
      0.15 + Math.random() * 0.5
    )
  }
}

;(function scheduleFlock() {
  setTimeout(() => {
    if (currentHudState === HUD_STATE.NORMAL) batFlock()
    scheduleFlock()
  }, 35000 + Math.random() * 40000)
})()

/* =====================================================
   GAME TIME UPDATE
   Fired every second by the game engine
===================================================== */
Events.Subscribe('UpdateTime', function (time) {
  /* Ignore timer updates during countdown */
  if (currentHudState === HUD_STATE.COUNTDOWN) return

  const minutes = Math.floor(time / 60)
  const seconds = time % 60

  timerEl.textContent = `${minutes.toString().padStart(2, '0')}:${seconds
    .toString()
    .padStart(2, '0')}`
})



/* =====================================================
   SCORE UPDATES
===================================================== */
Events.Subscribe('UpdateScoreA', (score) => {
  teamAScoreEl.textContent = score.toString()
  leaderboardScoreAEl.textContent = score.toString()
})

Events.Subscribe('UpdateScoreB', (score) => {
  teamBScoreEl.textContent = score.toString()
  leaderboardScoreBEl.textContent = score.toString()
})

/* =====================================================
   GOAL EVENT
   Triggered once per goal
===================================================== */
Events.Subscribe('GoalScored', function (goalInfo) {
  const { playerName, playerImageUrl, team, assistName, ownGoal } = goalInfo

  const scoreContainerEl = document.querySelector('#score-container')
  const goalPlayerCardEl = document.querySelector('#goal-player-card')
  const nameEl = document.querySelector('#goal-player-name')
  const avatarEl = document.querySelector('#goal-player-avatar')
  const detailEl = document.querySelector('#goal-player-detail')

  const teamClass = team === 1 ? 'team-a' : 'team-b'

  /* =====================
     HUD STATE
  ===================== */
  setHudState(HUD_STATE.GOAL)

  /* =====================
     TEAM COLOR SYNC
  ===================== */
  scoreContainerEl.classList.remove('team-a', 'team-b')
  goalPlayerCardEl.classList.remove('team-a', 'team-b')

  scoreContainerEl.classList.add(teamClass)
  goalPlayerCardEl.classList.add(teamClass)

  /* =====================
     CONTENT BINDING
  ===================== */
  nameEl.textContent = playerName
  detailEl.textContent = ownGoal
    ? `OWN GHOUL · A GIFT FOR THE ${TEAM_NAMES[team]}`
    : assistName
    ? `ASSIST · ${assistName}`
    : ''
  avatarEl.classList.toggle('no-avatar', !playerImageUrl)
  avatarEl.onerror = () => avatarEl.classList.add('no-avatar')
  if (playerImageUrl) avatarEl.src = playerImageUrl

  /* =====================
     PLAY ANIMATIONS
  ===================== */
  window.goalTl.restart()
  window.goalPlayerTl.restart()
  batBurst()

  /* =====================
     RESTORE HUD AFTER GOAL
  ===================== */
  window.goalTl.eventCallback('onComplete', () => {
    setHudState(HUD_STATE.NORMAL)
  })
})

/* =====================================================
   COUNTDOWN — EVENT DRIVEN
   Uses UpdateCountDownTime
===================================================== */
let countdownActive = false

Events.Subscribe('UpdateCountDownTime', function (second) {
  /* =====================
     COUNTDOWN ACTIVE
  ===================== */
  if (second > 0) {
    if (!countdownActive) {
      countdownActive = true
      setHudState(HUD_STATE.COUNTDOWN)

      /* Reset visual state (important for replays) */
      gsap.set('#countdown-number', {
        autoAlpha: 1,
        scale: 1,
      })

      window.countdownOutTl.pause(0)
      window.countdownInTl.restart()
    }

    countdownNumberEl.textContent = second.toString()
    window.countdownTickTl.restart()

    return
  }

  /* =====================
     COUNTDOWN END
  ===================== */
  if (second === 0 && countdownActive) {
    countdownActive = false

    window.countdownOutTl.eventCallback('onComplete', null)
    window.countdownOutTl.eventCallback('onComplete', () => {
      setHudState(HUD_STATE.NORMAL)
    })

    window.countdownOutTl.restart()
  }
})

/* =====================================================
   BOOST METER
   Fired by Client/Car.lua when the rounded boost changes
===================================================== */
const boostContainerEl = document.querySelector('#boost-container')
const boostValueEl = document.querySelector('#boost-value')
const boostFillEl = document.querySelector('#boost-fill')

Events.Subscribe('UpdateBoost', (boost) => {
  boostContainerEl.classList.remove('hidden')
  boostValueEl.textContent = boost.toString()
  boostFillEl.style.width = `${boost}%`
})

/* =====================================================
   BALL CAM INDICATOR
   Fired by Client/BallCam.lua when ball cam is toggled
===================================================== */
const ballCamEl = document.querySelector('#ball-cam')

Events.Subscribe('UpdateBallCam', (enabled) => {
  ballCamEl.classList.toggle('hidden', !enabled)
})

/* =====================================================
   YOUR NAME
   Fired by Client/NameTag.lua with your name and team (1 Witches, 2 Skeletons, 0 none yet)
===================================================== */
const myNameEl = document.querySelector('#my-name')
const myNameTextEl = document.querySelector('#my-name-text')
const myNameIconEl = document.querySelector('#my-name-icon')

Events.Subscribe('UpdateMyName', (name, team) => {
  myNameTextEl.textContent = name
  myNameEl.classList.toggle('team-a', team === 1)
  myNameEl.classList.toggle('team-b', team === 2)
  myNameIconEl.setAttribute('href', team === 2 ? '#icon-skull' : '#icon-hat')
  myNameEl.classList.toggle('hidden', !name)
})

/* =====================================================
   CONTROLS
   Fired by Client/Help.lua: the list (with the keys bound) and H to open it
===================================================== */
const controlsPanelEl = document.querySelector('#controls-panel')
const controlsHintKeyEl = document.querySelector('#controls-hint-key')

Events.Subscribe('UpdateControls', (rows, helpKey) => {
  controlsPanelEl.replaceChildren()
  for (const row of rows) {
    const keys = document.createElement('span')
    keys.className = 'controls-keys'
    for (const key of row.keys) {
      const keyEl = document.createElement('span')
      keyEl.className = 'controls-key'
      keyEl.textContent = key
      keys.appendChild(keyEl)
    }
    const action = document.createElement('span')
    action.textContent = row.action
    controlsPanelEl.append(keys, action)
  }
  controlsHintKeyEl.textContent = helpKey
})

Events.Subscribe('ToggleHelp', (open) => {
  controlsPanelEl.classList.toggle('hidden', !open)
})

/* =====================================================
   LEADERBOARD
   Rows sent by the server (Server/Stats.lua) every few
   seconds; held open with Tab, always open at game over
===================================================== */
const leaderboardOverlayEl = document.querySelector('#leaderboard-overlay')
const leaderboardRowsEls = {
  1: document.querySelector('#leaderboard-rows-a'),
  2: document.querySelector('#leaderboard-rows-b'),
}
const leaderboardContentEl = document.querySelector('#leaderboard-content')
const STAT_COLUMNS = ['score', 'goals', 'assists', 'hits']
// with more players than this in a team, rows get compact
const CROWDED_TEAM_SIZE = 6

let leaderboardRows = []
let leaderboardHeld = false
let gameOverInfo = null

function createAvatar(url) {
  const avatarEl = document.createElement('img')
  avatarEl.className = 'player-avatar'
  avatarEl.alt = ''
  if (url) {
    avatarEl.src = url
  } else {
    avatarEl.classList.add('no-avatar')
  }
  avatarEl.onerror = () => avatarEl.classList.add('no-avatar')
  return avatarEl
}

function renderLeaderboard() {
  const mvpId = gameOverInfo && gameOverInfo.mvp ? gameOverInfo.mvp.id : null

  for (const team of [1, 2]) {
    const bodyEl = leaderboardRowsEls[team]
    const rows = leaderboardRows
      .filter((row) => row.team === team)
      .sort(
        (a, b) =>
          b.score - a.score || b.goals - a.goals || a.name.localeCompare(b.name)
      )

    bodyEl.replaceChildren()

    if (rows.length === 0) {
      const tr = document.createElement('tr')
      tr.className = 'leaderboard-empty'
      const td = document.createElement('td')
      td.colSpan = 6
      td.textContent = 'NOBODY HERE... YET'
      tr.appendChild(td)
      bodyEl.appendChild(tr)
      continue
    }

    for (const row of rows) {
      const tr = document.createElement('tr')
      if (row.me) tr.classList.add('me')

      const nameTd = document.createElement('td')
      nameTd.className = 'col-name'
      const playerEl = document.createElement('div')
      playerEl.className = 'player-cell'
      const nameEl = document.createElement('span')
      nameEl.className = 'player-name'
      nameEl.textContent = row.name
      playerEl.append(createAvatar(row.avatar), nameEl)
      if (row.id === mvpId) {
        const starEl = document.createElement('span')
        starEl.className = 'mvp-star'
        starEl.textContent = '★'
        playerEl.appendChild(starEl)
      }
      nameTd.appendChild(playerEl)
      tr.appendChild(nameTd)

      for (const column of STAT_COLUMNS) {
        const td = document.createElement('td')
        td.className = `col-${column}`
        td.textContent = row[column].toString()
        tr.appendChild(td)
      }

      const pingTd = document.createElement('td')
      pingTd.className = 'col-ping'
      pingTd.textContent = `${row.ping}ms`
      tr.appendChild(pingTd)

      bodyEl.appendChild(tr)
    }
  }

  const teamSizes = [1, 2].map(
    (team) => leaderboardRows.filter((row) => row.team === team).length
  )
  leaderboardOverlayEl.classList.toggle(
    'crowded',
    Math.max(...teamSizes) > CROWDED_TEAM_SIZE
  )
  fitLeaderboard()
}

/**
 * Scales the leaderboard (and the game over result) down when it is
 * taller or wider than the screen
 */
function fitLeaderboard() {
  const margin = 48
  const scale = Math.min(
    1,
    (window.innerHeight - margin) / leaderboardContentEl.offsetHeight,
    (window.innerWidth - margin) / leaderboardContentEl.offsetWidth
  )
  leaderboardContentEl.style.transform = scale < 1 ? `scale(${scale})` : ''
}

window.addEventListener('resize', fitLeaderboard)
// the font changes the size once it loads
document.fonts.ready.then(fitLeaderboard)

function updateLeaderboardVisibility() {
  const visible = leaderboardHeld || gameOverInfo !== null
  gsap.to(leaderboardOverlayEl, {
    autoAlpha: visible ? 1 : 0,
    duration: visible ? 0.2 : 0.25,
    ease: visible ? 'power2.out' : 'power2.in',
  })
}

Events.Subscribe('UpdateLeaderboard', (rows) => {
  // an empty Lua table may arrive as an object
  leaderboardRows = Array.isArray(rows) ? rows : Object.values(rows || {})
  renderLeaderboard()
})

Events.Subscribe('ToggleLeaderboard', (open) => {
  leaderboardHeld = open
  updateLeaderboardVisibility()
})

/* =====================================================
   GAME OVER
   Result, MVP and the time to the next match, on top of
   the leaderboard until the server starts a new game
===================================================== */
const gameOverEl = document.querySelector('#game-over')
const gameOverTitleEl = document.querySelector('#game-over-title')
const gameOverScoreAEl = document.querySelector('#game-over-score-a')
const gameOverScoreBEl = document.querySelector('#game-over-score-b')
const gameOverMvpEl = document.querySelector('#game-over-mvp')
const gameOverMvpAvatarEl = document.querySelector('#game-over-mvp-avatar')
const gameOverMvpNameEl = document.querySelector('#game-over-mvp-name')
const nextGameEl = document.querySelector('#next-game')
const nextGameTimeEl = document.querySelector('#next-game-time')

Events.Subscribe('GameOver', (info) => {
  gameOverInfo = info

  const winnerClass =
    info.winner === 1 ? 'team-a' : info.winner === 2 ? 'team-b' : 'draw'
  gameOverTitleEl.className = `game-over-title ${winnerClass}`
  gameOverTitleEl.textContent =
    info.winner === 1 || info.winner === 2
      ? `${TEAM_NAMES[info.winner]} WIN!`
      : 'DEAD EVEN'

  gameOverScoreAEl.textContent = info.scoreA.toString()
  gameOverScoreBEl.textContent = info.scoreB.toString()

  if (info.mvp) {
    gameOverMvpEl.className = `game-over-mvp ${
      info.mvp.team === 2 ? 'team-b' : 'team-a'
    }`
    gameOverMvpNameEl.textContent = info.mvp.name
    gameOverMvpAvatarEl.classList.toggle('no-avatar', !info.mvp.avatar)
    if (info.mvp.avatar) gameOverMvpAvatarEl.src = info.mvp.avatar
  } else {
    gameOverMvpEl.className = 'game-over-mvp hidden'
  }

  nextGameTimeEl.textContent = info.nextGameIn.toString()

  gameOverEl.classList.remove('hidden')
  nextGameEl.classList.remove('hidden')
  leaderboardOverlayEl.classList.add('ended')

  setHudState(HUD_STATE.ENDED)
  renderLeaderboard()
  updateLeaderboardVisibility()

  /* =====================
     ENTER ANIMATION
  ===================== */
  gsap.fromTo(
    gameOverTitleEl,
    { letterSpacing: '56px', scaleX: 1.3, opacity: 0 },
    {
      letterSpacing: '12px',
      scaleX: 1,
      opacity: 1,
      duration: 0.9,
      ease: 'elastic.out(1, 0.45)',
    }
  )
  gsap.fromTo(
    ['.game-over-score', '#game-over-mvp', '.leaderboard-team', '#next-game'],
    { y: 18, opacity: 0 },
    {
      y: 0,
      opacity: 1,
      duration: 0.4,
      stagger: 0.1,
      ease: 'power3.out',
      delay: 0.25,
    }
  )
})

Events.Subscribe('UpdateNextGameTime', (seconds) => {
  nextGameTimeEl.textContent = seconds.toString()
})

Events.Subscribe('NewGame', () => {
  
  if (gameOverInfo === null) return
  gameOverInfo = null

  gameOverEl.classList.add('hidden')
  nextGameEl.classList.add('hidden')
  leaderboardOverlayEl.classList.remove('ended')

  renderLeaderboard()
  updateLeaderboardVisibility()
})
