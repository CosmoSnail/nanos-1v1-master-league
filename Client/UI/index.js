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

/* =====================================================
   HUD STATE MACHINE
   Controls which UI elements should be visible / active
===================================================== */
const HUD_STATE = {
  NORMAL: 'normal',
  GOAL: 'goal',
  COUNTDOWN: 'countdown',
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
})

Events.Subscribe('UpdateScoreB', (score) => {
  teamBScoreEl.textContent = score.toString()
})

/* =====================================================
   GOAL EVENT
   Triggered once per goal
===================================================== */
Events.Subscribe('GoalScored', function (goalInfo) {
  const { playerName, playerImageUrl, team } = goalInfo

  const scoreContainerEl = document.querySelector('#score-container')
  const goalPlayerCardEl = document.querySelector('#goal-player-card')
  const nameEl = document.querySelector('#goal-player-name')
  const avatarEl = document.querySelector('#goal-player-avatar')

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
  avatarEl.src = playerImageUrl

  /* =====================
     PLAY ANIMATIONS
  ===================== */
  window.goalTl.restart()
  window.goalPlayerTl.restart()

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
        filter: 'blur(0px)',
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
