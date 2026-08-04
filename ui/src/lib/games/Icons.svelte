<script lang="ts">
	import {
		faServer,
		faMicrochip,
		faTerminal,
		faCode,
		faCodeBranch,
		faDiagramProject,
		faCircleNodes,
		faSitemap,
		faShieldHalved,
		faNetworkWired,
		faFileCode,
		faBug,
		faBarcode,
		faKeyboard,
		faLaptopCode,
		faSatelliteDish,
		faWaveSquare,
		faCubes,
		faBrain,
		faAtom,
		faCodeCommit,
		faCodeMerge,
		type IconDefinition,
	} from '@fortawesome/free-solid-svg-icons';
	import { gameState, hideGame } from '../store/game.svelte';
	import { Nui } from '../nui';
	import { playSound } from '../sound';
	import type { ActiveGame, IconsGame } from '../types';

	const TICK_RATE = 10;

	const ICON_POOL: IconDefinition[] = [
		faServer,
		faMicrochip,
		faTerminal,
		faCode,
		faCodeBranch,
		faDiagramProject,
		faCircleNodes,
		faSitemap,
		faShieldHalved,
		faNetworkWired,
		faFileCode,
		faBug,
		faBarcode,
		faKeyboard,
		faLaptopCode,
		faSatelliteDish,
		faWaveSquare,
		faCubes,
		faBrain,
		faAtom,
		faCodeCommit,
		faCodeMerge,
	];

	const COLORS: { css: string; names: string[] }[] = [
		{ css: 'red', names: ['red'] },
		{ css: 'green', names: ['green'] },
		{ css: 'dodgerblue', names: ['blue'] },
		{ css: 'purple', names: ['purple'] },
		{ css: 'orange', names: ['orange'] },
		{ css: 'yellow', names: ['yellow'] },
		{ css: 'white', names: ['white'] },
		{ css: 'cyan', names: ['cyan'] },
		{ css: 'grey', names: ['grey', 'gray'] },
		{ css: 'hotpink', names: ['pink'] },
		{ css: '#00ff8a', names: ['mint'] },
	];

	interface GameIcon {
		icon: IconDefinition;
		color: { css: string; names: string[] };
		solved: boolean;
	}

	function sample<T>(arr: readonly T[]): T {
		return arr[Math.floor(Math.random() * arr.length)];
	}

	function svgPath(icon: IconDefinition) {
		return { path: icon.icon[4] as string, viewBox: `0 0 ${icon.icon[0]} ${icon.icon[1]}` };
	}

	const game = $derived(gameState.game as ActiveGame & IconsGame);

	let visible = $state(true);
	let ready = $state(false);
	let inputPhase = $state(false);
	let time = $state(0);
	let shuffle = $state(0);
	let correct = $state(0);
	let icons = $state<GameIcon[]>([]);
	let selected = $state<GameIcon | null>(null);
	let inputValue = $state('');
	let count = $state(5);

	let hideTimer: ReturnType<typeof setTimeout> | null = null;
	let countdownTimer: ReturnType<typeof setInterval> | null = null;
	let shuffleTimer: ReturnType<typeof setInterval> | null = null;
	let delayTimer: ReturnType<typeof setTimeout> | null = null;
	let tickTimer: ReturnType<typeof setInterval> | null = null;

	function clearTimers() {
		if (hideTimer) clearTimeout(hideTimer);
		if (countdownTimer) clearInterval(countdownTimer);
		if (shuffleTimer) clearInterval(shuffleTimer);
		if (delayTimer) clearTimeout(delayTimer);
		if (tickTimer) clearInterval(tickTimer);
		hideTimer = null;
		countdownTimer = null;
		shuffleTimer = null;
		delayTimer = null;
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
		if (gameState.finished || gameState.failed || !inputPhase) return;
		if (game.limit && time > game.limit) {
			onFinished(false);
		} else {
			time += TICK_RATE;
		}
	}

	function reshuffle() {
		const pool = [...ICON_POOL];
		const picked: GameIcon[] = [];
		for (let i = 0; i < game.difficulty && pool.length > 0; i++) {
			const idx = Math.floor(Math.random() * pool.length);
			const icon = pool.splice(idx, 1)[0];
			picked.push({ icon, color: sample(COLORS), solved: false });
		}
		icons = picked;
		selected = sample(picked);
		playSound('beep');
	}

	function onShuffleTick() {
		shuffle += 1;
		reshuffle();
		if (shuffle >= game.timer) {
			if (shuffleTimer) clearInterval(shuffleTimer);
			shuffleTimer = null;
			delayTimer = setTimeout(() => {
				inputPhase = true;
				playSound('confirm');
				tickTimer = setInterval(onTick, TICK_RATE);
			}, game.delay);
		}
	}

	function autofocus(node: HTMLElement) {
		node.focus();
	}

	function onSubmit(e: SubmitEvent) {
		e.preventDefault();
		if (gameState.finished || gameState.failed || !selected) return;

		if (selected.color.names.map((n) => n.toLowerCase()).includes(inputValue.trim().toLowerCase())) {
			correct += 1;
			playSound('positive');
			inputValue = '';
			icons = icons.map((i) => (i.icon === selected!.icon ? { ...i, solved: true } : i));
			const remaining = icons.filter((i) => !i.solved);
			if (correct >= game.difficulty2) {
				onFinished(true);
			} else if (remaining.length > 0) {
				selected = sample(remaining);
			}
		} else {
			onFinished(false);
		}
	}

	$effect(() => {
		void gameState.started;
		clearTimers();
		visible = true;
		ready = false;
		inputPhase = false;
		time = 0;
		shuffle = 0;
		correct = 0;
		icons = [];
		selected = null;
		inputValue = '';
		count = game.countdown ? game.countdown : 5;

		countdownTimer = setInterval(() => {
			count -= 1;
			if (count < 0 && countdownTimer) {
				clearInterval(countdownTimer);
				countdownTimer = null;
				ready = true;
				shuffleTimer = setInterval(onShuffleTick, 1000);
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
		{:else if ready}
			{#if !inputPhase}
				<div class="hint">Locating Input Sequence...</div>
				<div class="grid">
					{#each icons as gi, i (i)}
						{@const s = svgPath(gi.icon)}
						<svg viewBox={s.viewBox} class="icon" style:color={gi.color.css}><path d={s.path} /></svg>
					{/each}
				</div>
			{:else}
				<div class="hint">Sequence Located, Starting Decryption</div>
				<form onsubmit={onSubmit}>
					{#if selected}
						{@const s = svgPath(selected.icon)}
						<svg viewBox={s.viewBox} class="selected-icon"><path d={s.path} /></svg>
					{/if}
					<input type="text" bind:value={inputValue} placeholder="Color of Icon" use:autofocus />
				</form>
				<div class="progress-track">
					<div class="progress-fill" style:width="{100 - pct}%" style:background={barColor}></div>
				</div>
			{/if}
		{/if}
	</div>
{/if}

<style>
	.wrapper {
		width: 34vw;
		height: fit-content;
		min-height: 40vh;
		position: absolute;
		inset: 0;
		margin: auto;
		padding: 3vh 2vw;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
		pointer-events: auto;
	}
	.hint {
		text-align: center;
		font-family: var(--font-heading);
		font-size: 14px;
		color: var(--color-text-muted);
		margin-bottom: 2vh;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 2vh;
		place-items: center;
	}
	.icon {
		width: 2.2vw;
		height: 2.2vw;
		fill: currentColor;
	}
	.selected-icon {
		display: block;
		width: 6vw;
		height: 6vw;
		margin: 0 auto 2vh;
		fill: var(--color-text);
	}
	form {
		display: flex;
		justify-content: center;
	}
	input {
		width: 60%;
		height: 5vh;
		padding: 0 12px;
		background: var(--color-bg);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: var(--font-body);
		font-size: 14px;
		text-align: center;
	}
	input:focus {
		outline: none;
		border-color: var(--color-primary);
	}
	.progress-track {
		width: 100%;
		height: 8px;
		border-radius: var(--radius);
		background: var(--color-bg);
		margin-top: 2vh;
		overflow: hidden;
	}
	.progress-fill {
		height: 100%;
		transition: none;
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
