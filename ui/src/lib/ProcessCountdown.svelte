<!-- shared "hacking" preamble (3 flavor stages + numeric countdown) used by aim/captcha/keymaster/icons/tracking; parent wraps in {#key gameState.started} to reset it -->
<script lang="ts">
	import Icon from './Icon.svelte';

	const STAGE_DELAY = 4000;

	let { countdown, stageIcon, stageText, onready }: {
		countdown: number;
		stageIcon: string;
		stageText: string;
		onready: () => void;
	} = $props();

	let process = $state(0);
	let count = $state(countdown);

	$effect(() => {
		let readyFired = false;
		let stageTimer: ReturnType<typeof setInterval> | null = setInterval(() => {
			process += 1;
			if (process >= 3) {
				if (stageTimer) clearInterval(stageTimer);
				stageTimer = null;
				countTimer = setInterval(() => {
					count -= 1;
					if (count < 0) {
						if (countTimer) clearInterval(countTimer);
						countTimer = null;
						if (!readyFired) {
							readyFired = true;
							onready();
						}
					}
				}, 1000);
			}
		}, STAGE_DELAY);
		let countTimer: ReturnType<typeof setInterval> | null = null;

		return () => {
			if (stageTimer) clearInterval(stageTimer);
			if (countTimer) clearInterval(countTimer);
		};
	});
</script>

{#if process === 0}
	<div class="countdown">
		<div>
			<small>Attempting Security Bypass</small>
			<span><Icon name="spinner" spin /></span>
		</div>
	</div>
{:else if process === 1}
	<div class="countdown">
		<div>
			<small>Error Bypassing, Reconfiguring</small>
			<span class="error-icon"><Icon name="triangle-exclamation" /></span>
		</div>
	</div>
{:else if process === 2}
	<div class="countdown">
		<div>
			<small>{stageText}</small>
			<span><Icon name={stageIcon} /></span>
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

<style>
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
		line-height: 1;
		display: block;
		margin: auto;
		color: var(--color-text);
	}
	.error-icon {
		color: var(--color-error);
	}
</style>
