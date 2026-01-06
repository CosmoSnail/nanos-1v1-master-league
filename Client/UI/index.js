Events.Subscribe("UpdateTime", function(time) {
    const timer = document.querySelector('#timer');

    const minutes = Math.floor(time / 60);
    const seconds = time % 60;

    timer.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
});

Events.Subscribe("UpdateScoreA", function(score) {
    const teamAScore = document.querySelector('#team-a-score');
    teamAScore.textContent = `${score}`;
});

Events.Subscribe("UpdateScoreB", function(score) {
    const teamBScore = document.querySelector('#team-b-score');
    teamBScore.textContent = `${score}`;
});