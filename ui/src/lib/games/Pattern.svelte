<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import Icon from '../Icon.svelte';
	import type { ActiveGame, PatternGame } from '../types';

	interface Piece {
		character: string;
		isAnswer: boolean;
	}

	const STAGE_DELAY = 4000;
	const SHIFT_RATE = 1500;

	function randomInt(min: number, max: number) {
		return Math.floor(Math.random() * (max - min)) + min;
	}

	const game = $derived(gameState.game as ActiveGame & PatternGame);
	const charset = $derived(game.chance as string);
	const puzzleSize = $derived(game.size * 10);

	let charArray = $state<Piece[]>([]);
	let answerArray = $state<Piece[]>([]);
	let selected = $state(0);
	let visible = $state(true);
	let time = $state(0);
	let pressed = $state(false);
	let ready = $state(false);
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let stageTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let shiftTimer: ReturnType<typeof setInterval> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (stageTimer) clearTimeout(stageTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (shiftTimer) clearInterval(shiftTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		stageTimer = null;
		countdownTimer = null;
		shiftTimer = null;
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
		if (gameState.finished || gameState.failed) return;
		if (game.limit && time > game.limit) {
			onFinished(false);
		} else {
			time += 10;
		}
	}

	function onShift() {
		charArray = charArray.map((_, i, a) => a[(i + 1) % a.length]);
	}

	function isSelected(i: number) {
		return (
			(i >= selected && i < selected + game.difficulty) ||
			(selected + game.difficulty >= charArray.length - 1 && i < selected + game.difficulty - charArray.length)
		);
	}

	function onChange(v: number) {
		if (selected + v >= charArray.length) selected = selected + v - charArray.length;
		else if (selected + v < 0) selected = charArray.length + (selected + v);
		else selected = selected + v;
	}

	function onSubmit() {
		if (pressed || !ready || count >= 0) return;
		pressed = true;

		for (let i = 0; i < game.difficulty; i++) {
			let k = selected + i;
			if (k >= charArray.length) k -= charArray.length;
			if (!charArray[k]?.isAnswer) {
				onFinished(false);
				return;
			}
		}
		onFinished(true);
	}

	function onKeydown(e: KeyboardEvent) {
		switch (e.key.toLowerCase()) {
			case 'w':
				onChange(-10);
				break;
			case 's':
				onChange(10);
				break;
			case 'a':
				onChange(-1);
				break;
			case 'd':
				onChange(1);
				break;
			case ' ':
			case 'enter':
				onSubmit();
				break;
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		pressed = false;
		visible = true;
		ready = false;
		time = 0;
		count = game.countdown ? game.countdown : 5;

		const answerStart = randomInt(0, puzzleSize);
		const arr: Piece[] = [];
		for (let i = 0; i < puzzleSize; i++) {
			const isAnswer =
				(i >= answerStart && i < answerStart + game.difficulty) ||
				(answerStart + game.difficulty >= puzzleSize - 1 && i < answerStart + game.difficulty - puzzleSize);
			let character = '';
			for (let j = 0; j < game.difficulty2; j++) {
				character += charset.charAt(randomInt(0, charset.length));
			}
			arr.push({ character, isAnswer });
		}
		charArray = arr;
		answerArray = arr.filter((p) => p.isAnswer);
		selected = randomInt(0, puzzleSize);

		stageTimer = setTimeout(() => {
			ready = true;
			countdownTimer = setInterval(() => {
				count -= 1;
				if (count < 0 && countdownTimer) {
					clearInterval(countdownTimer);
					countdownTimer = null;
					tickTimer = setInterval(onTick, 10);
				}
			}, 1000);
		}, STAGE_DELAY);
		shiftTimer = setInterval(onShift, SHIFT_RATE);

		return clearTimers;
	});

	$effect(() => {
		window.addEventListener('keydown', onKeydown);
		return () => window.removeEventListener('keydown', onKeydown);
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
</script>

{#if visible}
	<div class="wrapper">
		{#if !ready}
			<div class="countdown">
				<div>
					<small>Manual Input Required</small>
					<span><Icon name="table-cells" /></span>
				</div>
			</div>
		{:else if count >= 0}
			<div class="countdown">
				<div>
					<small>Preparing System</small>
					<span>{count === 0 ? 'Done' : count}</span>
				</div>
			</div>
		{/if}

		{#if gameState.finished || gameState.failed}
			<div class="results">
				<div class="alert" class:success={gameState.finished} class:error={gameState.failed}>
					{resultLabel}
				</div>
			</div>
		{:else if ready && count < 0}
			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>

			<div class="answer-row">
				{#each answerArray as piece, i (i)}
					<div class="answer-char">{piece.character}</div>
				{/each}
			</div>

			<div class="char-row">
				{#each charArray as piece, i (i)}
					<div class="char" class:selected={isSelected(i)}>{piece.character}</div>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 34vw;
		height: fit-content;
		min-height: 32vh;
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
	.answer-row {
		display: flex;
		justify-content: center;
		gap: 6px;
		margin-bottom: 3vh;
	}
	.answer-char {
		font-size: 2vw;
		color: var(--color-text);
		font-family: var(--font-lcd);
	}
	.char-row {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 2px;
	}
	.char {
		width: 1.9vw;
		height: 1.9vw;
		line-height: 1.9vw;
		text-align: center;
		font-size: 1vw;
		font-family: var(--font-lcd);
		color: var(--color-text-muted);
	}
	.char.selected {
		color: var(--color-primary);
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
		font-size: 60px;
		display: block;
		margin: auto;
		color: var(--color-text);
	}
</style>
