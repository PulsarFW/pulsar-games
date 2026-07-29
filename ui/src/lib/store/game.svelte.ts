// Lua only ever pushes SHOW_GAME/FAIL_GAME — each game component decides pass/fail itself via Nui.finish()

import { Nui } from '../nui';
import keymap from '../keymap';
import keysets from '../keysets';
import charsets from '../charsets';
import type { ActiveGame, MinigameChance, MinigameDef, MinigameType } from '../types';

function getRandomChance(type: MinigameType, difficulty: number, extra?: unknown): MinigameChance {
	switch (type) {
		case 'skillbar':
			return Math.floor(Math.random() * difficulty) + 35;
		case 'scanner': {
			const total = extra as number;
			const min = difficulty === 0 ? 1 : 1 + difficulty;
			const max = total - difficulty;
			return Math.floor(Math.random() * (max - min + 1 - difficulty)) + min;
		}
		case 'sequencer': {
			const c: number[] = [];
			while (c.length < difficulty) {
				const r = Math.floor(Math.random() * 12) + 1;
				if (c[c.length - 1] !== r) c.push(r);
			}
			return c;
		}
		case 'memory': {
			const total = extra as number;
			const c: number[] = [];
			while (c.length < difficulty) {
				const r = Math.floor(Math.random() * total) + 1;
				if (c.indexOf(r) === -1) c.push(r);
			}
			return c;
		}
		case 'keypad': {
			const code = extra as string;
			return code
				.split('')
				.filter((c) => Boolean(c))
				.map((c) => +c) as unknown as MinigameChance;
		}
		case 'pattern': {
			const keys = Object.keys(charsets) as (keyof typeof charsets)[];
			const index = Math.floor(Math.random() * keys.length - 2);
			const requested = extra as string | false;
			let c: string = charsets[(requested || keys[index]) as keyof typeof charsets];
			if (!c) c = charsets.alphanumer;
			return c;
		}
		default:
			return extra as MinigameChance;
	}
}

function getRandomKey(type: MinigameType): string[] | string[][] {
	switch (type) {
		case 'skillbar':
			return ['e', 'E'];
		case 'round': {
			const keys = ['1', '2', '3'];
			return [keys[Math.floor(Math.random() * keys.length)]];
		}
		case 'scanner': {
			const k = keymap[Math.floor(Math.random() * keymap.length)];
			return [k.toLowerCase(), k.toUpperCase()];
		}
		case 'keymaster': {
			// one [lower, upper] pair per alley — indexed as game.key[alleyId] in Keymaster.svelte
			const set = keysets[Math.floor(Math.random() * keysets.length)];
			return set.map((key) => [key.toLowerCase(), key.toUpperCase()]);
		}
		default:
			return ['e', 'E'];
	}
}

export const gameState = $state({
	showing: false,
	game: null as ActiveGame | null,
	started: null as number | null,
	failed: false,
	finished: false,
});

export function handleGameMessage(type: string, data: unknown) {
	switch (type) {
		case 'SHOW_GAME': {
			const payload = data as { game: MinigameDef };
			const def = payload.game;
			const total = 'total' in def ? (def as unknown as { total: unknown }).total : undefined;
			gameState.showing = true;
			gameState.game = {
				...def,
				chance: getRandomChance(def.type, 'difficulty' in def ? (def.difficulty as number) : 0, total),
				key: 'randomKey' in def && def.randomKey ? getRandomKey(def.type) : ['e', 'E'],
			};
			gameState.started = Date.now();
			gameState.failed = false;
			gameState.finished = false;
			break;
		}
		case 'FAIL_GAME':
			gameState.failed = true;
			gameState.finished = false;
			break;
		case 'APP_HIDE':
			hideGame();
			break;
	}
}

/** Called by the active game component once it's shown its result state for a moment. */
export function hideGame() {
	Nui.end();
	gameState.showing = false;
	gameState.game = null;
	gameState.failed = false;
	gameState.finished = false;
}
