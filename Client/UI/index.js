/* =====================================================
   HUD REFERENCES (CACHE DOM)
===================================================== */
const timerEl = document.querySelector('#timer')
const teamAScoreEl = document.querySelector('#team-a-score')
const teamBScoreEl = document.querySelector('#team-b-score')

/* =====================================================
   GAME TIME UPDATE
   Recebe tempo em segundos e formata MM:SS
===================================================== */
Events.Subscribe('UpdateTime', function (time) {
  const minutes = Math.floor(time / 60)
  const seconds = time % 60

  timerEl.textContent = `${minutes.toString().padStart(2, '0')}:${seconds
    .toString()
    .padStart(2, '0')}`
})

/* =====================================================
   SCORE UPDATE — TEAM A
===================================================== */
Events.Subscribe('UpdateScoreA', function (score) {
  teamAScoreEl.textContent = score.toString()
})

/* =====================================================
   SCORE UPDATE — TEAM B
===================================================== */
Events.Subscribe('UpdateScoreB', function (score) {
  teamBScoreEl.textContent = score.toString()
})

/* =====================================================
   GOAL EVENT
   Triggers full-screen goal banner animation
===================================================== */
Events.Subscribe('GoalScored', function (info) {
  const timerContainerEl = document.querySelector('#timer-container');

  /* =====================
     HIDE TIMER
  ===================== */
  gsap.to(timerContainerEl, {
    opacity: 0,
    scale: 0.9,
    duration: 0.25,
    ease: 'power2.out',
  });

  /* =====================
     PLAY GOAL ANIMATION
  ===================== */
  window.goalTl.restart();

  /* =====================
     RESTORE TIMER
  ===================== */
  setTimeout(() => {
    gsap.to(timerContainerEl, {
      opacity: 1,
      scale: 1,
      duration: 0.4,
      ease: 'power3.out',
    });
  }, 5000);
});
