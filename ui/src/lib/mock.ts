// dev-only default params per game type, ported from the old reducer.js's sample states

import { mount } from 'svelte';
import { applyMessage } from './messages';
import type { MinigameDef, MinigameType } from './types';

export const DEMO_GAMES: Record<MinigameType, MinigameDef> = {
	skillbar: { type: 'skillbar', timer: 3000, difficulty: 10, needsMouse: false },
	round: { type: 'round', rate: 0.5, difficulty: 4, randomKey: true, needsMouse: false },
	scanner: {
		type: 'scanner',
		countdown: 5,
		timer: 40,
		total: 20,
		difficulty: 2,
		limit: 25000,
		randomKey: true,
		needsMouse: false,
	},
	sequencer: { type: 'sequencer', countdown: 10, timer: 250, limit: 5000, mask: true, difficulty: 4, needsMouse: true },
	keypad: { type: 'keypad', countdown: 3, limit: 10000, total: '1234', mask: true, needsMouse: true },
	scrambler: { type: 'scrambler', countdown: 5, timer: 3000, limit: 25000, total: 3, difficulty: 20, needsMouse: true },
	memory: {
		type: 'memory',
		countdown: 5,
		timer: 3000,
		limit: 25000,
		cols: 3,
		rows: 3,
		errors: 3,
		difficulty: 5,
		total: 9,
		needsMouse: true,
	},
	aim: {
		type: 'aim',
		countdown: 3,
		limit: 5000,
		timer: 1000,
		startSize: 25,
		maxSize: 75,
		difficulty: 25,
		accuracy: 25,
		isMoving: true,
		needsMouse: true,
	},
	captcha: { type: 'captcha', countdown: 3, timer: 5000, limit: 30000, difficulty: 5, difficulty2: 2, needsMouse: true },
	keymaster: {
		type: 'keymaster',
		countdown: 3,
		timer: [3500, 3500],
		limit: 35000,
		difficulty: 4,
		chances: 10,
		shuffled: false,
		randomKey: true,
		needsMouse: true,
	},
	pattern: {
		type: 'pattern',
		countdown: 3,
		limit: 350000,
		size: 6,
		difficulty: 4,
		difficulty2: 2,
		total: 'braille',
		needsMouse: true,
	},
	icons: {
		type: 'icons',
		countdown: 3,
		timer: 5,
		limit: 15000,
		delay: 1500,
		difficulty: 8,
		difficulty2: 8,
		needsMouse: true,
	},
	tracking: { type: 'tracking', countdown: 3, delay: 1500, limit: 15000, difficulty: 3, needsMouse: true },
};

export function launchGame(type: MinigameType): void {
	applyMessage('SHOW_GAME', { game: DEMO_GAMES[type] });
}

export async function startMock(): Promise<void> {
	const { default: DevMenu } = await import('./DevMenu.svelte');
	const node = document.createElement('div');
	document.body.appendChild(node);
	mount(DevMenu, { target: node });
}
