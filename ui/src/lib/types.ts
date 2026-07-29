// mirrors client/minigame.lua's MINIGAME.Play.* params. `events` is opaque (Lua closures don't survive JSON) — only used for Boolean(events?.onPerfect) checks in a few games.

export type SoundName = 'back' | 'beep' | 'confirm' | 'negative' | 'positive' | 'ticking';

interface BaseGame {
	needsMouse: boolean;
	data?: Record<string, unknown>;
	events?: { onPerfect?: unknown; onSuccess?: unknown; onFail?: unknown };
}

export interface SkillbarGame extends BaseGame {
	type: 'skillbar';
	timer: number;
	difficulty: number;
	needsMouse: false;
}

export interface RoundGame extends BaseGame {
	type: 'round';
	rate: number;
	difficulty: number;
	randomKey: true;
	needsMouse: false;
}

export interface ScannerGame extends BaseGame {
	type: 'scanner';
	countdown: number;
	timer: number;
	limit: number;
	total: number;
	difficulty: number;
	randomKey: boolean;
}

export interface SequencerGame extends BaseGame {
	type: 'sequencer';
	countdown: number;
	timer: number;
	limit: number;
	difficulty: number;
	mask: boolean;
}

export interface KeypadGame extends BaseGame {
	type: 'keypad';
	countdown: number;
	limit: number;
	total: string;
	mask: boolean;
}

export interface ScramblerGame extends BaseGame {
	type: 'scrambler';
	countdown: number;
	timer: number;
	limit: number;
	total: number;
	difficulty: number;
}

export interface MemoryGame extends BaseGame {
	type: 'memory';
	countdown: number;
	timer: number;
	limit: number;
	cols: number;
	rows: number;
	errors: number;
	difficulty: number;
	total: number;
}

export interface AimGame extends BaseGame {
	type: 'aim';
	countdown: number;
	limit: number;
	timer: number;
	startSize: number;
	maxSize: number;
	difficulty: number;
	accuracy: number;
	isMoving: boolean;
}

export interface CaptchaGame extends BaseGame {
	type: 'captcha';
	countdown: number;
	timer: number;
	limit: number;
	difficulty: number;
	difficulty2: number;
}

export interface KeymasterGame extends BaseGame {
	type: 'keymaster';
	countdown: number;
	timer: [number, number];
	limit: number;
	difficulty: number;
	chances: number;
	shuffled: boolean;
	randomKey: true;
}

export interface PatternGame extends BaseGame {
	type: 'pattern';
	countdown: number;
	limit: number;
	size: number;
	difficulty: number;
	difficulty2: number;
	total: string | false;
}

export interface IconsGame extends BaseGame {
	type: 'icons';
	countdown: number;
	timer: number;
	limit: number;
	delay: number;
	difficulty: number;
	difficulty2: number;
}

export interface TrackingGame extends BaseGame {
	type: 'tracking';
	countdown: number;
	delay: number;
	limit: number;
	difficulty: number;
}

export type MinigameDef =
	| SkillbarGame
	| RoundGame
	| ScannerGame
	| SequencerGame
	| KeypadGame
	| ScramblerGame
	| MemoryGame
	| AimGame
	| CaptchaGame
	| KeymasterGame
	| PatternGame
	| IconsGame
	| TrackingGame;

export type MinigameType = MinigameDef['type'];

/** chance shape varies per game type — single target, target list, or a charset string */
export type MinigameChance = number | number[] | string;

/** Game as resolved client-side, after the store rolls chance/key like the old reducer did */
export type ActiveGame = MinigameDef & {
	chance: MinigameChance;
	/** flat array of valid keys for most games; keymaster uses one [lower, upper] pair per alley (string[][]) */
	key: string[] | string[][];
};

/** 0 = fail, 1 = success, 2 = perfect — matches Minigame:Finish's data.state on the Lua side */
export type FinishState = 0 | 1 | 2;
