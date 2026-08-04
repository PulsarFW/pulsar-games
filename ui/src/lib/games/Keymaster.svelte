<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import ProcessCountdown from '../ProcessCountdown.svelte';
	import type { ActiveGame, KeymasterGame } from '../types';

	const TICK_RATE = 10;

	function shuffle<T>(arr: T[]): T[] {
		const a = [...arr];
		for (let i = a.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[a[i], a[j]] = [a[j], a[i]];
		}
		return a;
	}

	interface Alley {
		id: number;
		falling: boolean;
		offset: number;
		speed: number;
		pressed: boolean;
	}

	const game = $derived(gameState.game as ActiveGame & KeymasterGame & { key: string[][] });
	const alleyIds = $derived(game.shuffled ? shuffle(Array.from({ length: game.difficulty }, (_, i) => i)) : Array.from({ length: game.difficulty }, (_, i) => i));

	let visible = $state(true);
	let ready = $state(false);
	let time = $state(0);
	let fails = $state(0);
	let alleys = $state<Alley[]>([]);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;
	let fallTimer: ReturnType<typeof setInterval> | null = null;
	const respawnTimers = new Set<ReturnType<typeof setTimeout>>();

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (tickTimer) clearInterval(tickTimer);
		if (fallTimer) clearInterval(fallTimer);
		respawnTimers.forEach((t) => clearTimeout(t));
		respawnTimers.clear();
		hideTimer = null;
		tickTimer = null;
		fallTimer = null;
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

	function randomSpeed() {
		const [lo, hi] = game.timer;
		return Math.random() * (hi - lo) + lo;
	}

	function launchAlley(id: number, delay: number) {
		const t = setTimeout(() => {
			respawnTimers.delete(t);
			if (gameState.finished || gameState.failed) return;
			alleys = alleys.map((a) => (a.id === id ? { ...a, falling: true, offset: 0, speed: randomSpeed() } : a));
		}, delay);
		respawnTimers.add(t);
	}

	function stopAlley(id: number, hit: boolean) {
		alleys = alleys.map((a) => (a.id === id ? { ...a, falling: false, pressed: hit } : a));
		if (hit) playSound('beep');
		else {
			playSound('negative');
			fails += 1;
		}
		launchAlley(id, (Math.random() * 3 + 1) * 300);
		if (hit) {
			const t = setTimeout(() => {
				respawnTimers.delete(t);
				alleys = alleys.map((a) => (a.id === id ? { ...a, pressed: false } : a));
			}, 250);
			respawnTimers.add(t);
		}
	}

	function onFallTick() {
		if (gameState.finished || gameState.failed) return;
		for (const a of alleys) {
			if (a.falling && a.offset >= a.speed) {
				stopAlley(a.id, false);
			}
		}
		alleys = alleys.map((a) => (a.falling ? { ...a, offset: a.offset + TICK_RATE } : a));
	}

	function onTick() {
		if (gameState.finished || gameState.failed) return;
		if (game.limit && time > game.limit) {
			onFinished(true);
		} else {
			time += TICK_RATE;
		}
	}

	function onKeydown(e: KeyboardEvent) {
		if (!ready || gameState.finished || gameState.failed) return;
		const key = e.key;
		const alley = alleys.find((a) => a.falling && game.key[a.id]?.includes(key));
		if (!alley) return;

		const pctFallen = (alley.offset / alley.speed) * 100;
		stopAlley(alley.id, pctFallen >= 76 && pctFallen <= 88);
	}

	function onReady() {
		ready = true;
		alleys = alleyIds.map((id) => ({ id, falling: false, offset: 0, speed: randomSpeed(), pressed: false }));
		alleyIds.forEach((id, i) => launchAlley(id, (i === 0 ? 100 : 300) * (Math.random() * 3 + 1)));
		fallTimer = setInterval(onFallTick, TICK_RATE);
		tickTimer = setInterval(onTick, TICK_RATE);
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		visible = true;
		ready = false;
		time = 0;
		fails = 0;
		alleys = [];
		return clearTimers;
	});

	$effect(() => {
		if (ready && fails > game.chances) onFinished(false);
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
</script>

<svelte:window onkeydown={onKeydown} />

{#if visible}
	<div class="wrapper" style:min-width="calc(15vw * {game.difficulty})">
		{#key gameState.started}
			<ProcessCountdown
				countdown={game.countdown ? game.countdown : 5}
				stageIcon="chart-simple"
				stageText="Manual Verification Required"
				onready={onReady}
			/>
		{/key}

		{#if gameState.finished || gameState.failed}
			<div class="results">
				<div class="alert" class:success={gameState.finished} class:error={gameState.failed}>
					{resultLabel}
				</div>
			</div>
		{:else if ready}
			<div class="strikes">
				{#each Array(game.chances) as _, i (i)}
					<div class="strike" class:filled={fails > i}></div>
				{/each}
			</div>
			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>

			<div class="alleys">
				{#each alleys as alley (alley.id)}
					<div class="alley">
						{#if alley.falling}
							<div class="key" style:top="{(alley.offset / alley.speed) * 100}%">
								{game.key[alley.id]?.[1]}
							</div>
						{/if}
						<div class="key-zone">
							<div class="key target" class:pressed={alley.pressed}>
								{game.key[alley.id]?.[1]}
							</div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: fit-content;
		height: 78vh;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		pointer-events: auto;
		display: flex;
		flex-direction: column;
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
		height: 8px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-bottom: 2vh;
		overflow: hidden;
		flex-shrink: 0;
	}
	.progress-fill {
		height: 100%;
		transition: none;
	}
	.alleys {
		flex: 1;
		display: flex;
		justify-content: center;
		gap: 1.5vw;
	}
	.alley {
		width: 12vw;
		height: 100%;
		border-left: var(--border-subtle);
		border-right: var(--border-subtle);
		border-bottom: var(--border-subtle);
		position: relative;
		overflow: hidden;
	}
	.key-zone {
		height: 10%;
		width: 100%;
		position: absolute;
		bottom: 10%;
		left: 0;
		right: 0;
		margin: auto;
		border-top: 1px solid var(--color-info);
		border-bottom: 1px solid var(--color-info);
	}
	.key {
		height: 3.2vw;
		width: 3.2vw;
		position: absolute;
		left: 0;
		right: 0;
		margin: auto;
		border: var(--border-subtle);
		border-radius: var(--radius);
		text-align: center;
		line-height: 3.2vw;
		font-size: 1.3vw;
		font-family: var(--font-lcd);
		background: var(--color-bg);
		color: var(--color-text);
		transition: border-color ease-in 0.15s;
	}
	.key.target {
		top: 0;
		bottom: 0;
	}
	.key.pressed {
		border-color: var(--color-info);
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
</style>
