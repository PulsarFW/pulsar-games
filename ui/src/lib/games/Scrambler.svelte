<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, ScramblerGame } from '../types';

	const game = $derived(gameState.game as ActiveGame & ScramblerGame);
	const maxStrikes = $derived(game.chance as number);
	const hasPerfect = $derived(Boolean(game.events?.onPerfect));

	let sequence = $state<number[]>([]);
	let entered = $state<number[]>([]);
	let strikes = $state(0);
	let submitting = $state(false);
	let pressed = $state(false);
	let visible = $state(true);
	let time = $state(0);
	let time2 = $state(0);
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;
	let submitTimer: ReturnType<typeof setTimeout> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (tickTimer) clearInterval(tickTimer);
		if (submitTimer) clearTimeout(submitTimer);
		hideTimer = null;
		countdownTimer = null;
		tickTimer = null;
		submitTimer = null;
	}

	function generateSequence() {
		const c: number[] = [];
		while (c.length < game.difficulty) {
			const r = Math.floor(Math.random() * game.difficulty) + 1;
			if (!c.includes(r)) c.push(r);
		}
		sequence = c;
	}

	function scheduleSubmitting() {
		submitting = false;
		if (submitTimer) clearTimeout(submitTimer);
		submitTimer = setTimeout(() => {
			submitting = true;
		}, 1000);
	}

	const pct = $derived(Math.min((time / game.limit) * 100, 100));
	const pct2 = $derived(Math.min((time2 / game.timer) * 100, 100));

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

	function onComplete() {
		if (pressed) return;
		pressed = true;
		onFinished(true, strikes === 0 && hasPerfect);
	}

	function onBtnPress(digit: number) {
		if (entered.length >= game.difficulty || gameState.finished || gameState.failed || pct2 >= 100) return;

		if (entered.length + 1 === digit) {
			playSound('beep');
			entered = [...entered, digit];
			if (entered.length >= game.difficulty) onComplete();
		} else if (strikes >= maxStrikes) {
			if (pressed) return;
			pressed = true;
			onFinished(false, false);
		} else {
			playSound('negative');
			strikes += 1;
		}
	}

	function tick() {
		if (gameState.finished || gameState.failed || count >= 0) return;

		if (entered.length < game.difficulty) {
			if (game.limit && time > game.limit) {
				if (!pressed) {
					pressed = true;
					onFinished(false, false);
				}
			} else {
				time += 10;
			}
		}

		if (entered.length < game.difficulty && submitting) {
			if (game.timer && time2 > game.timer) {
				scheduleSubmitting();
				time2 = 0;
				generateSequence();
			} else {
				time2 += 10;
			}
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		pressed = false;
		visible = true;
		entered = [];
		strikes = 0;
		time = 0;
		time2 = 0;
		count = game.countdown ? game.countdown : 5;
		generateSequence();
		scheduleSubmitting();

		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
			}
		}, 1000);
		tickTimer = setInterval(tick, 10);

		return clearTimers;
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
	const barColor = $derived(pct < 33 ? 'var(--color-success)' : pct < 66 ? 'var(--color-warning)' : 'var(--color-error)');
	const critical = $derived(!gameState.finished && !gameState.failed && (pct >= 66 || strikes >= maxStrikes));
</script>

{#if visible}
	<div class="wrapper" class:critical>
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
				{#each Array(maxStrikes) as _, i (i)}
					<div class="strike" class:filled={strikes > i}></div>
				{/each}
			</div>

			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>

			<div class="grid">
				{#each sequence as digit (digit)}
					<button
						class:used={entered.length >= digit}
						disabled={entered.length >= game.difficulty || entered.length >= digit}
						onclick={() => onBtnPress(digit)}
					>
						{digit}
					</button>
				{/each}
			</div>

			<div class="progress-track thin">
				<div class="progress-fill" style:width="{100 - pct2}%"></div>
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 24vw;
		min-height: 40vh;
		height: fit-content;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: 3px solid transparent;
		border-radius: var(--radius);
		pointer-events: auto;
	}
	.wrapper.critical {
		animation:
			critical 1s infinite,
			critical-border 1s infinite;
	}
	.strikes {
		display: flex;
		gap: 5px;
		margin-bottom: 12px;
	}
	.strike {
		flex: 1;
		height: 20px;
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
		margin-bottom: 20px;
		overflow: hidden;
	}
	.progress-track.thin {
		height: 5px;
		margin-bottom: 0;
		margin-top: 8px;
	}
	.progress-fill {
		height: 100%;
		background: var(--color-primary);
		transition: none;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
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
	button:not(:disabled):hover {
		background: var(--color-bg-panel-alt);
	}
	button.used {
		background: var(--color-info);
		color: var(--color-text);
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
