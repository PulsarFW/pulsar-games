<!-- hand-picks a small fixed icon set since Lua never supplies an arbitrary icon name for this resource -->
<script lang="ts">
	import {
		faCheck,
		faXmark,
		faLock,
		faLockOpen,
		faCrosshairs,
		faChevronUp,
		faChevronDown,
		faChevronLeft,
		faChevronRight,
		faSpinner,
		faTriangleExclamation,
		faPenToSquare,
		faLocationCrosshairs,
		faCircleCheck,
		faCircleXmark,
		faTableCells,
		faChartSimple,
		faIcons,
		type IconDefinition,
	} from '@fortawesome/free-solid-svg-icons';

	const ICONS: Record<string, IconDefinition> = {
		check: faCheck,
		xmark: faXmark,
		lock: faLock,
		'lock-open': faLockOpen,
		crosshairs: faCrosshairs,
		'chevron-up': faChevronUp,
		'chevron-down': faChevronDown,
		'chevron-left': faChevronLeft,
		'chevron-right': faChevronRight,
		spinner: faSpinner,
		'triangle-exclamation': faTriangleExclamation,
		'pen-to-square': faPenToSquare,
		'location-crosshairs': faLocationCrosshairs,
		'circle-check': faCircleCheck,
		'circle-xmark': faCircleXmark,
		'table-cells': faTableCells,
		'chart-simple': faChartSimple,
		icons: faIcons,
	};

	let { name, size = '1em', spin = false }: { name: string; size?: string; spin?: boolean } = $props();

	const icon = $derived(ICONS[name] ?? faXmark);
	const path = $derived(icon.icon[4] as string);
	const viewBox = $derived(`0 0 ${icon.icon[0]} ${icon.icon[1]}`);
</script>

<svg {viewBox} width={size} height={size} fill="currentColor" aria-hidden="true" class:spin>
	<path d={path} />
</svg>

<style>
	.spin {
		animation: spin 1s linear infinite;
	}
	@keyframes spin {
		from {
			transform: rotate(0deg);
		}
		to {
			transform: rotate(360deg);
		}
	}
</style>
