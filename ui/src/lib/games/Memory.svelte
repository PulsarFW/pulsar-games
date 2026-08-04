<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, MemoryGame } from '../types';

	const TICK_RATE = 10;

	const game = $derived(gameState.game as ActiveGame & MemoryGame);
	const targets = $derived(game.chance as number[]);
	const hasPerfect = $derived(Boolean(game.events?.onPerfect));
	const total = $derived(game.cols * game.rows);

	let entered = $state<number[]>([]);
	let strikes = $state<number[]>([]);
	let submitting = $state(false);
	let visible = $state(true);
	let time = $state(0);
	let time2 = $state(0);
	let pressed = $state(false);
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let previewTimer: ReturnType<typeof setInterval> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (previewTimer) clearInterval(previewTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		countdownTimer = null;
		previewTimer = null;
		tickTimer = null;
	}

	const pct = $derived(game.limit ? (time / game.limit) * 100 : 0);
	const pct2 = $derived(game.timer ? (time2 / game.timer) * 100 : 0);

	function isDone(list: number[]) {
		const found = list.filter((d) => targets.includes(d));
		const allFound = found.length >= targets.length && targets.every((t) => found.includes(t));
		return allFound || strikes.length >= game.errors;
	}

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

	function onPreviewTick() {
		if (time2 >= game.timer) {
			submitting = true;
			if (previewTimer) clearInterval(previewTimer);
			previewTimer = null;
			tickTimer = setInterval(onTick, TICK_RATE);
		} else {
			time2 += TICK_RATE;
		}
	}

	function onTick() {
		if (gameState.finished || gameState.failed) return;
		if (game.limit && time > game.limit) {
			if (pressed) return;
			pressed = true;
			onFinished(false, false);
		} else {
			time += TICK_RATE;
		}
	}

	function onBtnPress(digit: number) {
		if (!submitting || gameState.finished || gameState.failed || entered.includes(digit)) return;
		playSound('beep');
		if (!targets.includes(digit)) strikes = [...strikes, digit];
		entered = [...entered, digit];

		if (isDone(entered)) {
			if (pressed) return;
			pressed = true;
			const success = strikes.length < game.errors;
			onFinished(success, success && strikes.length === 0 && hasPerfect);
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		pressed = false;
		visible = true;
		entered = [];
		strikes = [];
		submitting = false;
		time = 0;
		time2 = 0;
		count = game.countdown ? game.countdown : 5;

		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
				previewTimer = setInterval(onPreviewTick, TICK_RATE);
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
					<small>Preparing Device</small>
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
			<div class="strikes">
				{#each Array(game.errors) as _, i (i)}
					<div class="strike" class:filled={strikes.length > i}></div>
				{/each}
			</div>

			<div class="progress-track" class:thin={submitting}>
				{#if submitting}
					<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
				{:else}
					<div class="progress-fill" style:width="{100 - pct2}%" style:background="var(--color-info)"></div>
				{/if}
			</div>

			<div class="grid" style:grid-template-columns="repeat({game.cols}, 1fr)">
				{#each Array(total) as _, idx (idx)}
					{@const digit = idx + 1}
					{@const isEntered = entered.includes(digit)}
					{@const isTarget = targets.includes(digit)}
					<button
						class="tile"
						class:preview={!submitting && isTarget}
						class:highlight={submitting && isEntered && isTarget}
						class:wrong={submitting && isEntered && !isTarget}
						class:clickable={submitting && !isEntered}
						disabled={!submitting || isEntered}
						onclick={() => onBtnPress(digit)}
						aria-label="tile {digit}"
					></button>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: fit-content;
		min-width: 22vw;
		height: fit-content;
		min-height: 36vh;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		pointer-events: auto;
	}
	.strikes {
		display: flex;
		gap: 6px;
		margin-bottom: 1.5vh;
	}
	.strike {
		flex: 1;
		height: 1.5vh;
		background: var(--color-bg);
		border-radius: var(--radius);
		transition: background ease-in 0.15s;
	}
	.strike.filled {
		background: var(--color-primary);
	}
	.progress-track {
		width: 100%;
		height: 20px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-bottom: 2vh;
		overflow: hidden;
	}
	.progress-track.thin {
		height: 5px;
	}
	.progress-fill {
		height: 100%;
		transition: none;
	}
	.grid {
		display: grid;
		gap: 6px;
	}
	.tile {
		width: 4.5vw;
		height: 4.5vw;
		border: var(--border-subtle);
		border-radius: var(--radius);
		background: var(--color-bg);
		cursor: default;
	}
	.tile.clickable:hover {
		border-color: var(--color-primary);
		cursor: pointer;
	}
	.tile.preview {
		background: var(--color-info);
	}
	.tile.highlight {
		background: var(--color-success);
	}
	.tile.wrong {
		background: var(--color-error);
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
