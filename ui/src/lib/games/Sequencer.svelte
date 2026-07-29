<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, SequencerGame } from '../types';

	const TICK_RATE = 10;

	const game = $derived(gameState.game as ActiveGame & SequencerGame);
	const sequence = $derived(game.chance as number[]);
	const hasPerfect = $derived(Boolean(game.events?.onPerfect));

	let entered = $state<number[]>([]);
	let submitting = $state(false);
	let flashing = $state<number[]>([]);
	let visible = $state(true);
	let time = $state(0);
	let pressed = $state(false);
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let flashTimer: ReturnType<typeof setInterval> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (flashTimer) clearInterval(flashTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		countdownTimer = null;
		flashTimer = null;
		tickTimer = null;
	}

	const pct = $derived((time / game.limit) * 100);

	function onFinished(success: boolean, perfect: boolean) {
		if (success) {
			gameState.finished = true;
			Nui.finish(perfect ? 2 : 1);
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

	function addFlashed() {
		if (sequence.length === flashing.length) {
			if (flashTimer) clearInterval(flashTimer);
			flashTimer = null;
			submitting = true;
			tickTimer = setInterval(onTick, TICK_RATE);
		} else {
			flashing = [...flashing, sequence[flashing.length]];
		}
	}

	function onTick() {
		if (entered.length >= game.difficulty || gameState.finished || gameState.failed || !submitting) return;

		if (game.limit && time > game.limit) {
			if (pressed) return;
			pressed = true;
			onFinished(false, false);
		} else {
			time += TICK_RATE;
		}
	}

	function onBtnPress(digit: number) {
		if (entered.length >= game.difficulty || gameState.finished || gameState.failed) return;
		playSound('beep');
		entered = [...entered, digit];
		if (entered.length === sequence.length) onComplete();
	}

	function onComplete() {
		if (pressed) return;
		pressed = true;

		const match = entered.length === sequence.length && entered.every((v, i) => v === sequence[i]);
		onFinished(match, match && pct <= 25 && hasPerfect);
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		pressed = false;
		visible = true;
		entered = [];
		submitting = false;
		flashing = [];
		time = 0;
		count = game.countdown ? game.countdown : 5;

		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
				flashTimer = setInterval(addFlashed, game.timer);
			}
		}, 1000);

		return clearTimers;
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
	const barColor = $derived(pct < 33 ? 'var(--color-success)' : pct < 66 ? 'var(--color-warning)' : 'var(--color-error)');
</script>

{#if visible}
	<div class="wrapper">
		{#if count >= 0}
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
		{:else if count < 0}
			<div class="output">
				{#if entered.length > 0}
					{#each entered as digit, k (k)}
						<span class="digit">{game.mask ? '*' : digit}</span>
					{/each}
				{:else}
					<span class="no-input">No Input</span>
				{/if}
			</div>
			<div class="progress-track">
				{#if submitting}
					<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
				{/if}
			</div>
			<div class="grid">
				{#each Array(12) as _, idx (idx)}
					{@const n = idx + 1}
					<button
						class:flash={flashing[flashing.length - 1] === n && !submitting}
						disabled={entered.length >= game.difficulty || !submitting}
						onclick={() => onBtnPress(n)}
					>
						{n}
					</button>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 24vw;
		min-height: 46vh;
		height: fit-content;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		pointer-events: auto;
	}
	.output {
		width: 100%;
		text-align: right;
		height: 75px;
		line-height: 75px;
		font-family: var(--font-lcd);
	}
	.digit {
		font-size: 42px;
		color: var(--color-text);
		padding: 5px;
	}
	.no-input {
		font-size: 42px;
		color: var(--color-text-muted);
	}
	.progress-track {
		width: 100%;
		height: 20px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-bottom: 20px;
		overflow: hidden;
	}
	.progress-fill {
		height: 100%;
		transition: none;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 8px;
	}
	button {
		height: 75px;
		background: var(--color-bg);
		color: var(--color-text);
		border: none;
		border-radius: var(--radius);
		font-size: 42px;
		font-family: var(--font-lcd);
		cursor: pointer;
		transition: background ease-in 0.15s;
	}
	button:disabled {
		cursor: default;
		opacity: 0.6;
	}
	button:not(:disabled):not(.flash):hover {
		background: var(--color-bg-panel-alt);
	}
	button.flash {
		background: var(--color-gold);
		color: var(--color-bg);
	}
	.results {
		width: 100%;
		height: 100%;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 30px;
		background: color-mix(in srgb, var(--color-bg) 70%, transparent);
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
