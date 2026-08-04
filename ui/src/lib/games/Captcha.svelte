<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, CaptchaGame } from '../types';

	const SHAPES = ['square', 'triangle', 'rectangle', 'circle'] as const;
	const COLORABLE = ['background', 'colortext', 'shapetext', 'number', 'shape'] as const;
	const COLORS: Record<string, string> = {
		black: '#000000',
		white: '#FFFFFF',
		blue: '#2195ee',
		red: '#7b0100',
		yellow: '#fceb3d',
		orange: '#fd9802',
		green: '#4cae4f',
		purple: '#9926ac',
	};
	const COLOR_NAMES = Object.keys(COLORS);

	interface Piece {
		index: number;
		shape: (typeof SHAPES)[number];
		number: number;
		text: [string, string];
		colors: Record<(typeof COLORABLE)[number], string>;
	}

	function randomInt(max: number) {
		return Math.floor(Math.random() * max);
	}
	function sample<T>(arr: readonly T[]): T {
		return arr[randomInt(arr.length)];
	}

	function randomizePiece(index: number): Piece {
		const shape = sample(SHAPES);
		const number = randomInt(9) + 1;
		const topText = sample(COLOR_NAMES);
		const bottomText = sample(SHAPES);

		const names: Record<string, string> = {};
		for (const c of COLORABLE) names[c] = sample(COLOR_NAMES);

		while (['colortext', 'shapetext'].map((k) => names[k]).includes(names.background)) {
			names.background = sample(COLOR_NAMES);
		}
		while (['background', 'colortext', 'shapetext', 'number'].map((k) => names[k]).includes(names.shape)) {
			names.shape = sample(COLOR_NAMES);
		}

		const colors = {} as Record<(typeof COLORABLE)[number], string>;
		for (const c of COLORABLE) colors[c] = COLORS[names[c]];

		return { index, shape, number, text: [topText, bottomText], colors };
	}

	const QUESTIONS: Record<string, (p: Piece) => string> = {
		'background color': (p) => p.colors.background,
		'color text color': (p) => p.colors.colortext,
		'shape text color': (p) => p.colors.shapetext,
		'number color': (p) => p.colors.number,
		'shape color': (p) => p.colors.shape,
		'color text': (p) => p.text[0],
		'shape text': (p) => p.text[1],
		shape: (p) => p.shape,
	};

	function generateQuestionAndAnswer(numAnswers: number, pieces: Piece[]) {
		const usedQuestions: string[] = [];
		const usedPositions: number[] = [];
		const parts: { question: string; position: number }[] = [];
		const answers: string[] = [];
		const questionKeys = Object.keys(QUESTIONS);

		for (let i = 0; i < numAnswers && i < pieces.length - 1 && i < questionKeys.length; i++) {
			let pos: number;
			do {
				pos = randomInt(pieces.length - 1) + 1;
			} while (usedPositions.includes(pos));
			usedPositions.push(pos);

			let que: string;
			do {
				que = sample(questionKeys);
			} while (usedQuestions.includes(que));
			usedQuestions.push(que);

			const result = QUESTIONS[que](pieces[pos]);
			const named = Object.keys(COLORS).find((k) => COLORS[k] === result);
			answers.push(named ?? result);
			parts.push({ question: que, position: pos });
		}

		return { parts, answer: answers.join(' ') };
	}

	const game = $derived(gameState.game as ActiveGame & CaptchaGame);

	let visible = $state(true);
	let ready = $state(false);
	let submitted = $state(false);
	let time = $state(0);
	let count = $state(5);
	let pieces = $state<Piece[]>([]);
	let question = $state<{ question: string; position: number }[]>([]);
	let answer = $state('');
	let inputValue = $state('');

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let revealTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (revealTimer) clearTimeout(revealTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		countdownTimer = null;
		revealTimer = null;
		tickTimer = null;
	}

	const pct = $derived(game.limit ? (time / game.limit) * 100 : 0);
	const barColor = $derived(pct < 33 ? 'var(--color-success)' : pct < 66 ? 'var(--color-warning)' : 'var(--color-error)');

	function onFinished(success: boolean) {
		if (success) {
			gameState.finished = true;
			Nui.finish(1);
			playSound('positive');
		} else {
			gameState.failed = true;
			Nui.finish(0);
			playSound('negative');
		}
		hideTimer = setTimeout(() => {
			visible = false;
		}, 2000);
	}

	function onTick() {
		if (gameState.finished || gameState.failed || submitted) return;
		if (game.limit && time > game.limit) {
			onFinished(false);
		} else {
			time += 10;
		}
	}

	function autofocus(node: HTMLElement) {
		node.focus();
	}

	function onSubmit(e: SubmitEvent) {
		e.preventDefault();
		if (gameState.finished || gameState.failed || submitted) return;
		submitted = true;
		onFinished(inputValue.trim().toLowerCase() === answer.toLowerCase());
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		visible = true;
		ready = false;
		submitted = false;
		time = 0;
		inputValue = '';
		count = game.countdown ? game.countdown : 5;

		const nums = Array.from({ length: game.difficulty }, (_, i) => i);
		const f = nums.map((i) => randomizePiece(i));
		const qa = generateQuestionAndAnswer(game.difficulty2, f);
		pieces = f;
		question = qa.parts;
		answer = qa.answer;

		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
				revealTimer = setTimeout(() => {
					ready = true;
					playSound('confirm');
					tickTimer = setInterval(onTick, 10);
				}, game.timer);
			}
		}, 1000);

		return clearTimers;
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
</script>

{#if visible}
	<div class="wrapper" style:min-width="calc(15vw * {game.difficulty})">
		{#if count >= 0}
			<div class="countdown">
				<div>
					<small>Preparing System</small>
					<span>{count === 0 ? 'Done' : count}</span>
				</div>
			</div>
		{:else if !ready}
			<div class="countdown">
				<div>
					<small>Decrypting Puzzle</small>
				</div>
			</div>
		{/if}

		{#if gameState.finished || gameState.failed}
			<div class="results">
				<div class="alert" class:success={gameState.finished} class:error={gameState.failed}>
					{resultLabel}
				</div>
			</div>
		{:else if count < 0 && ready}
			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>

			<div class="puzzle-row">
				{#each pieces as piece (piece.index)}
					<svg class="piece" viewBox="0 0 150 150" style:background={piece.colors.background}>
						{#if piece.shape === 'square'}
							<rect fill={piece.colors.shape} width="150" height="150" />
						{:else if piece.shape === 'triangle'}
							<polygon fill={piece.colors.shape} points="0 150 75 0 150 150 0 150" />
						{:else if piece.shape === 'rectangle'}
							<rect y="30" fill={piece.colors.shape} width="150" height="90" />
						{:else}
							<circle fill={piece.colors.shape} cx="75" cy="75" r="75" />
						{/if}
						<text x="50%" y="25%" fill={piece.colors.colortext} font-size="22" font-weight="bold" text-anchor="middle" dominant-baseline="middle">
							{piece.text[0].toUpperCase()}
						</text>
						<text x="50%" y="70%" fill={piece.colors.shapetext} font-size="22" font-weight="bold" text-anchor="middle" dominant-baseline="middle">
							{piece.text[1].toUpperCase()}
						</text>
						<text x="50%" y="50%" fill={piece.colors.number} font-size="50" font-weight="bold" text-anchor="middle" dominant-baseline="middle">
							{piece.number}
						</text>
					</svg>
				{/each}
			</div>

			<div class="qa">
				<div class="question">
					ENTER
					{#each question as q, i (i)}
						<b>{q.question} ( {q.position} )</b>{i < question.length - 1 ? ' AND' : ''}
					{/each}
				</div>
				<form onsubmit={onSubmit}>
					<input type="text" bind:value={inputValue} disabled={submitted} placeholder="Answer" use:autofocus />
					<button type="submit" disabled={submitted}>Submit</button>
				</form>
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: fit-content;
		height: fit-content;
		min-height: 42vh;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		pointer-events: auto;
	}
	.progress-track {
		width: 100%;
		height: 8px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-bottom: 2vh;
		overflow: hidden;
	}
	.progress-fill {
		height: 100%;
		transition: none;
	}
	.puzzle-row {
		display: flex;
		gap: 1vw;
		justify-content: center;
	}
	.piece {
		width: 9vw;
		height: 9vw;
		border-radius: var(--radius);
		border: var(--border-subtle);
	}
	.qa {
		margin-top: 2.5vh;
		text-align: center;
	}
	.question {
		text-transform: uppercase;
		font-family: var(--font-heading);
		font-size: 14px;
		color: var(--color-text-muted);
		letter-spacing: 0.02em;
		margin-bottom: 1.5vh;
	}
	.question b {
		color: var(--color-text);
		margin: 0 6px;
	}
	form {
		display: flex;
		gap: 8px;
		justify-content: center;
	}
	input {
		width: 12vw;
		height: 5vh;
		padding: 0 12px;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: var(--font-body);
		font-size: 14px;
	}
	input:focus {
		outline: none;
		border-color: var(--color-primary);
	}
	button[type='submit'] {
		height: 5vh;
		padding: 0 18px;
		background: var(--color-primary);
		color: var(--color-text);
		border: none;
		border-radius: var(--radius);
		font-family: var(--font-heading);
		cursor: pointer;
	}
	button[type='submit']:disabled {
		opacity: 0.6;
		cursor: default;
	}
	.results {
		width: 100%;
		height: 100%;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 30px;
		background: var(--color-bg-overlay);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 10;
	}
	.alert {
		width: 300px;
		padding: 14px;
		border-radius: var(--radius);
		text-align: center;
		font-family: var(--font-heading);
		font-weight: 600;
		letter-spacing: 0.02em;
		color: var(--color-text);
	}
	.alert.success {
		background: var(--color-success);
	}
	.alert.error {
		background: var(--color-error);
	}
	.countdown {
		position: absolute;
		inset: 0;
		background: rgba(0, 0, 0, 0.25);
		border-radius: var(--radius);
		z-index: 100;
	}
	.countdown > div {
		width: fit-content;
		height: fit-content;
		position: absolute;
		inset: 0;
		margin: auto;
		text-align: center;
	}
	.countdown small {
		font-size: 28px;
		font-family: var(--font-lcd);
		display: block;
		margin: auto;
		color: var(--color-text);
	}
	.countdown span {
		font-size: 100px;
		font-family: var(--font-lcd);
		display: block;
		margin: auto;
		color: var(--color-text);
	}
</style>
