<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import ProcessCountdown from '../ProcessCountdown.svelte';
	import type { ActiveGame, AimGame } from '../types';

	const TICK_RATE = 10;
	const MOVE_INTERVAL = 2600;

	function random(min: number, max: number) {
		return Math.random() * (max - min) + min;
	}

	interface Target {
		id: number;
		x: number;
		y: number;
		spawnedAt: number;
	}

	const game = $derived(gameState.game as ActiveGame & AimGame);

	let containerEl: HTMLDivElement | undefined = $state();
	let visible = $state(true);
	let ready = $state(false);
	let time = $state(0);
	let hit = $state(0);
	let missed = $state(0);
	let targets = $state<Target[]>([]);
	let nextId = 1;

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;
	let spawnTimer: ReturnType<typeof setTimeout> | null = null;
	let growTimer: ReturnType<typeof setInterval> | null = null;
	let moveTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (tickTimer) clearInterval(tickTimer);
		if (spawnTimer) clearTimeout(spawnTimer);
		if (growTimer) clearInterval(growTimer);
		if (moveTimer) clearInterval(moveTimer);
		hideTimer = null;
		tickTimer = null;
		spawnTimer = null;
		growTimer = null;
		moveTimer = null;
	}

	const pct = $derived(Math.min((time / game.limit) * 100, 100));
	const accuracy = $derived(hit + missed > 0 ? Math.floor((hit / (hit + missed)) * 100) : 0);
	const barColor = $derived(pct < 33 ? 'var(--color-success)' : pct < 66 ? 'var(--color-warning)' : 'var(--color-error)');

	function targetSize(target: Target) {
		const grown = Math.floor((Date.now() - target.spawnedAt) / game.difficulty);
		return Math.min(game.startSize + grown, game.maxSize);
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

	function spawnTarget() {
		if (!containerEl) return;
		const size = game.maxSize;
		const x = random(0, Math.max(containerEl.clientWidth - size, 0));
		const y = random(0, Math.max(containerEl.clientHeight - size, 0));
		targets = [...targets, { id: nextId++, x, y, spawnedAt: Date.now() }];
		spawnTimer = setTimeout(spawnTarget, game.timer);
	}

	function onHit(id: number) {
		if (gameState.finished || gameState.failed) return;
		hit += 1;
		playSound('beep');
		targets = targets.filter((t) => t.id !== id);
	}

	function onMiss() {
		if (gameState.finished || gameState.failed) return;
		missed += 1;
		playSound('negative');
	}

	function onGrowTick() {
		if (gameState.finished || gameState.failed) return;
		const overgrown = targets.filter((t) => targetSize(t) >= game.maxSize);
		if (overgrown.length > 0) {
			targets = targets.filter((t) => targetSize(t) < game.maxSize);
			missed += overgrown.length;
			playSound('negative');
		}
	}

	function onMoveTick() {
		if (!containerEl || !game.isMoving) return;
		const size = game.maxSize;
		targets = targets.map((t) => ({
			...t,
			x: random(0, Math.max(containerEl!.clientWidth - size, 0)),
			y: random(0, Math.max(containerEl!.clientHeight - size, 0)),
		}));
	}

	function onTick() {
		if (gameState.finished || gameState.failed) return;
		if (time > game.limit) {
			onFinished(accuracy >= game.accuracy, accuracy === 100);
		} else {
			time += TICK_RATE;
		}
	}

	function onReady() {
		ready = true;
		spawnTimer = setTimeout(spawnTarget, game.timer / 4);
		growTimer = setInterval(onGrowTick, TICK_RATE);
		moveTimer = setInterval(onMoveTick, MOVE_INTERVAL);
		tickTimer = setInterval(onTick, TICK_RATE);
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		visible = true;
		ready = false;
		time = 0;
		hit = 0;
		missed = 0;
		targets = [];
		return clearTimers;
	});

	$effect(() => {
		if (!visible) hideGame();
	});

	const resultLabel = $derived(gameState.finished ? 'Success!' : gameState.failed ? 'You Failed' : '');
</script>

{#if visible}
	<div class="wrapper">
		{#key gameState.started}
			<ProcessCountdown
				countdown={game.countdown ? game.countdown : 5}
				stageIcon="location-crosshairs"
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
			<div class="scoreboard">
				<span>Hits: {hit}, Misses: {missed}</span>
				<span>Accuracy: {accuracy}%, Required: {game.accuracy}%</span>
			</div>
			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>
			<div class="aim-container" bind:this={containerEl} onclick={onMiss} role="presentation">
				{#each targets as target (target.id)}
					{@const size = targetSize(target)}
					<button
						class="target"
						style:left="{target.x}px"
						style:top="{target.y}px"
						style:width="{size}px"
						style:height="{size}px"
						onclick={(e) => {
							e.stopPropagation();
							onHit(target.id);
						}}
						aria-label="target"
					></button>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 82vw;
		height: 74vh;
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
	.scoreboard {
		display: flex;
		justify-content: space-between;
		padding: 0 4px 1.5vh;
		font-family: var(--font-heading);
		font-size: 15px;
		color: var(--color-text);
	}
	.progress-track {
		width: 100%;
		height: 8px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-bottom: 1.5vh;
		overflow: hidden;
		flex-shrink: 0;
	}
	.progress-fill {
		height: 100%;
		transition: none;
	}
	.aim-container {
		position: relative;
		flex: 1;
		background: var(--color-bg);
		border-radius: var(--radius);
		cursor: crosshair;
	}
	.target {
		position: absolute;
		border-radius: 50%;
		background: var(--color-bg-panel-alt);
		border: 2px solid var(--color-primary);
		transition: left 0.6s ease, top 0.6s ease, width 0.15s linear, height 0.15s linear;
		cursor: pointer;
		padding: 0;
	}
	.target:hover {
		border-color: var(--color-primary-light);
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
</style>
