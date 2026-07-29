<script lang="ts">
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import ProcessCountdown from '../ProcessCountdown.svelte';
	import type { ActiveGame, TrackingGame } from '../types';

	const TICK_RATE = 10;
	const COLOR_CODES = ['#00ffff', '#088f90', '#708fae', '#7392b2', '#6394ed', '#10487f', '#0047ab', '#1335a3', '#00018b'];

	function random(min: number, max: number) {
		return Math.floor(Math.random() * (max - min)) + min;
	}

	interface Target {
		id: number;
		x: number;
		y: number;
		color: string;
	}

	const game = $derived(gameState.game as ActiveGame & TrackingGame);

	let containerEl: HTMLDivElement | undefined = $state();
	let visible = $state(true);
	let ready = $state(false);
	let preview = $state(true);
	let time = $state(0);
	let entered = $state(0);
	let targets = $state<Target[]>([]);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let previewTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (previewTimer) clearTimeout(previewTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		previewTimer = null;
		tickTimer = null;
	}

	const pct = $derived(Math.min((time / game.limit) * 100, 100));
	const barColor = $derived(preview ? 'var(--color-info)' : pct < 33 ? 'var(--color-success)' : pct < 66 ? 'var(--color-warning)' : 'var(--color-error)');

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
		if (gameState.finished || gameState.failed || preview) return;
		if (time > game.limit) {
			onFinished(false);
		} else {
			time += TICK_RATE;
		}
	}

	function onClickTarget(id: number) {
		if (preview || gameState.finished || gameState.failed) return;
		if (id === entered + 1) {
			entered = id;
			playSound('beep');
			if (entered === game.difficulty) onFinished(true);
		} else {
			onFinished(false);
		}
	}

	function onReady() {
		ready = true;
		if (!containerEl) return;
		const colors = [...COLOR_CODES].sort(() => Math.random() - 0.5);
		targets = Array.from({ length: game.difficulty }, (_, i) => ({
			id: i + 1,
			x: random(0, Math.max(containerEl!.clientWidth - 150, 0)),
			y: random(0, Math.max(containerEl!.clientHeight - 150, 0)),
			color: colors[i % colors.length],
		}));
		previewTimer = setTimeout(() => {
			preview = false;
			playSound('confirm');
		}, game.delay);
		tickTimer = setInterval(onTick, TICK_RATE);
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		visible = true;
		ready = false;
		preview = true;
		time = 0;
		entered = 0;
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
				stageIcon="table-cells"
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
			<div class="progress-track">
				<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
			</div>
			<div class="aim-container" bind:this={containerEl}>
				{#each targets.filter((t) => t.id > entered) as target (target.id)}
					<button
						class="target"
						style:left="{target.x}px"
						style:top="{target.y}px"
						style:background={target.color}
						onclick={() => onClickTarget(target.id)}
					>
						{#if preview}{target.id}{/if}
					</button>
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 68vw;
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
	}
	.target {
		position: absolute;
		height: 100px;
		width: 100px;
		border: var(--border-subtle);
		text-align: center;
		line-height: 100px;
		font-size: 24px;
		font-family: var(--font-heading);
		color: var(--color-bg);
		cursor: pointer;
		padding: 0;
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
