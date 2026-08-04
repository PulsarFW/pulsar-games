<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, ScannerGame } from '../types';

	const game = $derived(gameState.game as ActiveGame & ScannerGame & { key: string[] });
	const chance = $derived(game.chance as number);
	const hasPerfect = $derived(Boolean(game.events?.onPerfect));

	let pressed = $state(false);
	let visible = $state(true);
	let change = $state(1);
	let current = $state(0);
	let stopped = $state(false);
	let time = $state(0);
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		countdownTimer = null;
		tickTimer = null;
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

	function onKeydown(e: KeyboardEvent) {
		if (pressed || count >= 0 || !game.key.includes(e.key)) return;
		pressed = true;
		stopped = true;

		const inZone = current >= chance - game.difficulty && current <= chance + game.difficulty;
		onFinished(inZone, current === chance && hasPerfect);
	}

	function startTimers() {
		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
				tickTimer = setInterval(tick, game.timer);
			}
		}, 1000);
	}

	function tick() {
		if (stopped || gameState.finished || gameState.failed) return;

		if (game.limit && time > game.limit) {
			onFinished(false, false);
			return;
		}

		if (current >= game.total) change = -1;
		else if (current <= 1) change = 1;
		current += change;
		time += game.timer;
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		pressed = false;
		stopped = false;
		visible = true;
		time = 0;
		const r = Math.ceil(Math.random() * (game.total - 1));
		change = r === game.total - 1 ? -1 : 1;
		current = r;
		count = game.countdown ? game.countdown : 5;
		startTimers();
		return clearTimers;
	});

	$effect(() => {
		window.addEventListener('keydown', onKeydown);
		return () => window.removeEventListener('keydown', onKeydown);
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	interface Bar {
		i: number;
		active: boolean;
		variant: 'default' | 'valid' | 'gold';
		showHotkey: boolean;
	}

	const bars = $derived.by((): Bar[] => {
		const out: Bar[] = [];
		for (let i = 1; i <= game.total; i++) {
			const inZone = i >= chance - game.difficulty && i <= chance + game.difficulty && count < 0;
			const active = current === i && (count < 0 || inZone);
			if (inZone) {
				const gold = i === chance && hasPerfect;
				out.push({
					i,
					active,
					variant: gold ? 'gold' : 'valid',
					showHotkey: !gameState.finished && !gameState.failed && (gold || i === chance),
				});
			} else {
				out.push({ i, active: active && count < 0, variant: 'default', showHotkey: false });
			}
		}
		return out;
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
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
		{/if}

		<div class="bars">
			{#each bars as bar (bar.i)}
				<div class="bar {bar.variant}" class:active={bar.active} class:ended={gameState.finished || gameState.failed}>
					{#if bar.showHotkey}
						<div class="hotkey">{game.key[0]?.toUpperCase()}</div>
					{/if}
				</div>
			{/each}
		</div>

		{#if game.limit}
			<div class="timer">{time / 1000}s / {game.limit / 1000}s</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 75%;
		height: 65%;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2.5vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
	}
	.bars {
		padding: 10px;
		height: 100%;
		background: var(--color-bg);
		display: flex;
		gap: 5px;
		border-radius: var(--radius);
	}
	.bar {
		height: 100%;
		flex: 1;
		background: var(--color-error-dark);
		position: relative;
		border-radius: calc(var(--radius) - 1px);
	}
	.bar.valid {
		background: var(--color-info-dark);
	}
	.bar.gold {
		background: var(--color-gold);
	}
	.bar.active {
		background: var(--color-success);
	}
	.bar.ended {
		transition: background ease-in 0.15s;
		background: var(--color-bg-panel-alt);
	}
	.hotkey {
		font-size: 50px;
		font-family: var(--font-lcd);
		color: var(--color-text);
		height: fit-content;
		width: fit-content;
		position: absolute;
		inset: 0;
		margin: auto;
		text-shadow: 0 0 5px var(--color-bg-panel-alt);
	}
	.bar.gold .hotkey {
		color: var(--color-bg);
	}
	.timer {
		text-align: center;
		margin: 8px auto 0;
		font-size: 18px;
		font-family: var(--font-lcd);
		color: var(--color-text);
		text-shadow: 0 0 5px #000;
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
		z-index: 100;
		border-radius: var(--radius);
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
