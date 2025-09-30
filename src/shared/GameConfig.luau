--# selene: allow(shadowing)
local RunService = game:GetService("RunService")

local function i(s: string) return `<i>{s}</i>` end
local function t(s: string, t: number)
	return `<font transparency="{t}">{s}</font>`
end
local function s(s: string, sz: number) return `<font size="{sz}">{s}</font>` end
local function b(s: string) return `<b>{s}</b>` end
local function c(s: string, c: string) return `<font color="{c}">{s}</font>` end
local function u(s: string) return `<u>{s}</u>` end

local Config = {}

Config.Version = `0.0.0`
	.. (
		RunService:IsStudio() and "-PLAYTEST"
		or `-prealpha ({game.PlaceVersion})`
	)

Config.Changelog = {}

Config.Welcome = {
	s(
		`Welcome to {b(
			`{c(`Project D:`, "#ffaaaa")} {s(i(`Driving Masters`), 22)}`
		)}`,
		24
	),
	``,
	`This game is a {i(`racing simulator`)} that tries to replicate the behaviour of a {i(
		`real`
	)} car.`
		.. ` Here you can customize your car for {`drifting`}, {`drag racing`}, {`touge`}, {t(
			i(`or just keep it stock`),
			0.1
		)}`,
	``,
	b(`Features:`),
	`- Vehicle deformation!`,
	t(i(`   Vehicles can get deformed, scratched, and dirty.`), 0.1),
	`- Tires wear system`,
	t(
		i(
			`   Tires can become dirty and worn out, losing their original appearance and grip.`
		),
		0.1
	),
	`- Engine damage and wear system`,
	t(i(`   Be careful, because your engine is not immortal!`), 0.1),
	u(`These and other cool and realistic features are in this game!`),
	``,
	b(`Made with {c(`love`, "#ffaaaa")}, {i(`please enjoy!`)}`),
	``,
	`{t(`Current version: {i(Config.Version)}`, 0.1)}`,
}

return Config
